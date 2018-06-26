#!/usr/bin/env bash

IP_ADDRESS=$(ip -4 addr show eth0 | grep -oP "(?<=inet).*(?=/)"| sed -e "s/^[[:space:]]*//" | tail -n 1)

# Ensure correct ownership and permissions on volumes
chown vernemq:vernemq /var/lib/vernemq /var/log/vernemq
chmod 755 /var/lib/vernemq /var/log/vernemq

# Ensure the Erlang node name is set correctly
if env | grep -q "DOCKER_VERNEMQ_NODENAME"; then
    sed -i.bak -r "s/VerneMQ@.+/VerneMQ@${DOCKER_VERNEMQ_NODENAME}/" /etc/vernemq/vm.args
else
    sed -i.bak -r "s/VerneMQ@.+/VerneMQ@${IP_ADDRESS}/" /etc/vernemq/vm.args
fi

if env | grep -q "DOCKER_VERNEMQ_DISCOVERY_NODE"; then
    echo "-eval \"vmq_server_cmd:node_join('VerneMQ@${DOCKER_VERNEMQ_DISCOVERY_NODE}')\"" >> /etc/vernemq/vm.args
fi

# If you encounter "SSL certification error (subject name does not match the host name)", you may try to set DOCKER_VERNEMQ_KUBERNETES_INSECURE to "1".
insecure=""
if env | grep -q "DOCKER_VERNEMQ_KUBERNETES_INSECURE"; then
    insecure="--insecure"
fi

if env | grep -q "DOCKER_VERNEMQ_DISCOVERY_KUBERNETES"; then
    # Let's set our nodename correctly
    VERNEMQ_KUBERNETES_SUBDOMAIN=$(curl -X GET $insecure --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://kubernetes.default.svc.cluster.local/api/v1/namespaces/$DOCKER_VERNEMQ_KUBERNETES_NAMESPACE/pods?labelSelector=app=$DOCKER_VERNEMQ_KUBERNETES_APP_LABEL -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" | jq '.items[0].spec.subdomain' | sed 's/"//g' | tr '\n' '\0')
    VERNEMQ_KUBERNETES_HOSTNAME=${MY_POD_NAME}.${VERNEMQ_KUBERNETES_SUBDOMAIN}.${DOCKER_VERNEMQ_KUBERNETES_NAMESPACE}.svc.cluster.local

    sed -i.bak -r "s/VerneMQ@.+/VerneMQ@${VERNEMQ_KUBERNETES_HOSTNAME}/" /etc/vernemq/vm.args
    # Hack into K8S DNS resolution (temporarily)
    kube_pod_names=$(curl -X GET $insecure --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://kubernetes.default.svc.cluster.local/api/v1/namespaces/$DOCKER_VERNEMQ_KUBERNETES_NAMESPACE/pods?labelSelector=app=$DOCKER_VERNEMQ_KUBERNETES_APP_LABEL -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" | jq '.items[].spec.hostname' | sed 's/"//g' | tr '\n' ' ')
    for kube_pod_name in $kube_pod_names;
    do
        if [ $kube_pod_name == "null" ]
            then
                echo "Kubernetes discovery selected, but no pods found. Maybe we're the first?"
                echo "Anyway, we won't attempt to join any cluster."
                break
        fi
        if [ $kube_pod_name != $MY_POD_NAME ]
            then
                echo "Will join an existing Kubernetes cluster with discovery node at ${kube_pod_name}.${VERNEMQ_KUBERNETES_SUBDOMAIN}.${DOCKER_VERNEMQ_KUBERNETES_NAMESPACE}.svc.cluster.local"
                echo "-eval \"vmq_server_cmd:node_join('VerneMQ@${kube_pod_name}.${VERNEMQ_KUBERNETES_SUBDOMAIN}.${DOCKER_VERNEMQ_KUBERNETES_NAMESPACE}.svc.cluster.local')\"" >> /etc/vernemq/vm.args
                break
        fi
    done
fi

if [ -n "$DOCKER_VERNEMQ_DISCOVERY_SWARM" ]; then
    # Let's set our nodename correctly
    IP_ADDRESS=$(hostname -i)
    sed -i.bak -r "s/VerneMQ@.+/VerneMQ@${IP_ADDRESS}/" /etc/vernemq/vm.args

    stack_name() {
        echo -n $SERVICE_LABELS | awk '{match($0,"com.docker.stack.namespace:[a-zA-Z0-9-_]+")}END{print substr($0,RSTART+27,RLENGTH-27)}'
    }

    service_base_name() {
        echo -n "${SERVICE_NAME#$(stack_name)_}"
    }

    cluster_members() {
        vmq-admin cluster show | awk '{for (i=1; i<=NF; i++){tmp=match($i, "VerneMQ\@[0-9\.]+"); if (tmp) {print substr($0,RSTART+8,RLENGTH-8)}}}'
    }

    service_replicas() {
        getent hosts tasks.$(service_base_name) | awk '{print $1}'
    }

    stranded_replicas() {
        comm -23 <(service_replicas | sort) <(cluster_members | sort)
    }

    heal() {
        new_acquaintance=$(stranded_replicas | shuf | head -n 1)
        if [ -n "$new_acquaintance" ]; then
            vmq-admin cluster join discovery-node="VerneMQ@$new_acquaintance"
        fi
    }

    export -f stack_name
    export -f service_base_name
    export -f cluster_members
    export -f service_replicas
    export -f stranded_replicas
    export -f heal
    (while true; do heal; sleep 2; done &)
fi

if [ -f /etc/vernemq/vernemq.conf.local ]; then
    cp /etc/vernemq/vernemq.conf.local /etc/vernemq/vernemq.conf
else
    sed -i '/########## Start ##########/,/########## End ##########/d' /etc/vernemq/vernemq.conf

    echo "########## Start ##########" >> /etc/vernemq/vernemq.conf

    env | grep DOCKER_VERNEMQ | grep -v 'DISCOVERY_NODE\|KUBERNETES\|SWARM\|DOCKER_VERNEMQ_USER' | cut -c 16- | awk '{match($0,/^[A-Z0-9_]*/)}{print tolower(substr($0,RSTART,RLENGTH)) substr($0,RLENGTH+1)}' | sed 's/__/./g' >> /etc/vernemq/vernemq.conf

    users_are_set=$(env | grep DOCKER_VERNEMQ_USER)
    if [ ! -z "$users_are_set" ]; then
        echo "vmq_passwd.password_file = /etc/vernemq/vmq.passwd" >> /etc/vernemq/vernemq.conf
        touch /etc/vernemq/vmq.passwd
    fi

    for vernemq_user in $(env | grep DOCKER_VERNEMQ_USER); do
        username=$(echo $vernemq_user | awk -F '=' '{ print $1 }' | sed 's/DOCKER_VERNEMQ_USER_//g' | tr '[:upper:]' '[:lower:]')
        password=$(echo $vernemq_user | awk -F '=' '{ print $2 }')
        vmq-passwd /etc/vernemq/vmq.passwd $username <<EOF
$password
$password
EOF
    done

    echo "erlang.distribution.port_range.minimum = 9100" >> /etc/vernemq/vernemq.conf
    echo "erlang.distribution.port_range.maximum = 9109" >> /etc/vernemq/vernemq.conf
    echo "listener.tcp.default = ${IP_ADDRESS}:1883" >> /etc/vernemq/vernemq.conf
    echo "listener.ws.default = ${IP_ADDRESS}:8080" >> /etc/vernemq/vernemq.conf
    echo "listener.vmq.clustering = ${IP_ADDRESS}:44053" >> /etc/vernemq/vernemq.conf
    echo "listener.http.metrics = ${IP_ADDRESS}:8888" >> /etc/vernemq/vernemq.conf

    echo "########## End ##########" >> /etc/vernemq/vernemq.conf
fi

# Check configuration file
su - vernemq -c "/usr/sbin/vernemq config generate 2>&1 > /dev/null" | tee /tmp/config.out | grep error

if [ $? -ne 1 ]; then
    echo "configuration error, exit"
    echo "$(cat /tmp/config.out)"
    exit $?
fi

pid=0

# SIGUSR1-handler
siguser1_handler() {
    echo "stopped"
}

# SIGTERM-handler
sigterm_handler() {
    if [ $pid -ne 0 ]; then
        # this will stop the VerneMQ process
        vmq-admin cluster leave node=VerneMQ@$IP_ADDRESS -k > /dev/null
        wait "$pid"
    fi
    exit 143; # 128 + 15 -- SIGTERM
}

# Setup OS signal handlers
trap 'siguser1_handler' SIGUSR1
trap 'sigterm_handler' SIGTERM

# Start VerneMQ
/usr/sbin/vernemq console -noshell -noinput $@
pid=$(ps aux | grep '[b]eam.smp' | awk '{print $2}')
wait $pid