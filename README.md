# docker-vernemq

## What is VerneMQ?

VerneMQ is a high-performance, distributed MQTT message broker. It scales
horizontally and vertically on commodity hardware to support a high number of
concurrent publishers and consumers while maintaining low latency and fault
tolerance. VerneMQ is the reliable message hub for your IoT platform or smart
products.

VerneMQ is an Apache2 licensed distributed MQTT broker, developed in Erlang.

## How to use this image

### 1. Accepting the VerneMQ EULA

**NOTE:** To use the official Docker images you have to accept the [VerneMQ End
User License Agreement](https://vernemq.com/end-user-license-agreement). You can
read how to accept the VerneMQ EULA
[here](https://docs.vernemq.com/installation/accepting-the-vernemq-eula).

**NOTE 2 (TL:DR)**:
To use the binary Docker packages (that is, the official packages from Docker Hub) or the VerneMQ binary Linux packages commercially and legally, you need a paid subscription. Accepting the EULA is your promise to do that. To avoid a subscription, you need to clone this repository and build and host your own Dockerfiles/-images.

### 2. Using [Helm](https://helm.sh/) to deploy on [Kubernetes](https://kubernetes.io/)

First install and configure Helm according to the [documentation](https://helm.sh/docs/using_helm/#quickstart-guide). Then add VerneMQ Helm charts repository:

    helm repo add vernemq https://vernemq.github.io/docker-vernemq

You can now deploy VerneMQ on your Kubernetes cluster:

    helm install vernemq/vernemq

For more information, check out the Helm chart [README](helm/vernemq/README.md).

### 3. Using pure Docker commands

    docker run -e "DOCKER_VERNEMQ_ACCEPT_EULA=yes" --name vernemq1 -d vernemq/vernemq

Sometimes you need to configure a forwarding for ports (on a Mac for example):

    docker run -p 1883:1883 -e "DOCKER_VERNEMQ_ACCEPT_EULA=yes" --name vernemq1 -d vernemq/vernemq

This starts a new node that listens on 1883 for MQTT connections and on 8080 for MQTT over websocket connections. However, at this moment the broker won't be able to authenticate the connecting clients. To allow anonymous clients use the ```DOCKER_VERNEMQ_ALLOW_ANONYMOUS=on``` environment variable.

    docker run -e "DOCKER_VERNEMQ_ACCEPT_EULA=yes" -e "DOCKER_VERNEMQ_ALLOW_ANONYMOUS=on" --name vernemq1 -d vernemq/vernemq

#### Autojoining a VerneMQ cluster

This allows a newly started container to automatically join a VerneMQ cluster. Assuming you started your first node like the example above you could autojoin the cluster (which currently consists of a single container 'vernemq1') like the following:

    docker run -e "DOCKER_VERNEMQ_ACCEPT_EULA=yes" -e "DOCKER_VERNEMQ_DISCOVERY_NODE=<IP-OF-VERNEMQ1>" --name vernemq2 -d vernemq/vernemq

(Note, you can find the IP of a docker container using `docker inspect <containername/cid> | grep \"IPAddress\"`).


### 4. Automated clustering on Kubernetes without helm

When running VerneMQ inside Kubernetes, it is possible to cause pods matching a specific label to cluster altogether automatically.
This feature uses Kubernetes' API to discover other peers, and relies on the [default pod service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) which has to be enabled.

Simply set ```DOCKER_VERNEMQ_DISCOVERY_KUBERNETES=1``` in your pod's environment, and expose your own pod name through ```MY_POD_NAME``` . By default, this setting will cause all pods in the same namespace with the ```app=vernemq``` label to join the same cluster. Cluster name (defaults to `cluster.local`), namespace and label settings can be overridden with ```DOCKER_VERNEMQ_KUBERNETES_CLUSTER_NAME```, ```DOCKER_VERNEMQ_KUBERNETES_NAMESPACE``` and ```DOCKER_VERNEMQ_KUBERNETES_LABEL_SELECTOR``` respectively.

An example configuration of your pod's environment looks like this:

    env:
      - name: DOCKER_VERNEMQ_DISCOVERY_KUBERNETES
        value: "1"
      - name: MY_POD_NAME
        valueFrom:
          fieldRef:
            fieldPath: metadata.name
      - name: DOCKER_VERNEMQ_KUBERNETES_LABEL_SELECTOR
        value: "app=vernemq,release=myinstance"

When enabling Kubernetes autoclustering, don't set ```DOCKER_VERNEMQ_DISCOVERY_NODE```.

> If you encounter "SSL certification error (subject name does not match the host name)" like below, you may try to set ```DOCKER_VERNEMQ_KUBERNETES_INSECURE``` to "1".
>
> ```text
> kubectl logs vernemq-0
>   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
>                                  Dload  Upload   Total   Spent    Left  Speed
>   0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0curl: (51) SSL: certificate subject name 'client' does not match target host name 'kubernetes.default.svc.cluster.local'
>   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
>                                  Dload  Upload   Total   Spent    Left  Speed
>   0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0curl: (51) SSL: certificate subject name 'client' does not match target host name 'kubernetes.default.svc.cluster.local'
> vernemq failed to start within 15 seconds,
> see the output of 'vernemq console' for more information.
> If you want to wait longer, set the environment variable
> WAIT_FOR_ERLANG to the number of seconds to wait.
> ...
> ```
If using an vernemq.conf.local file, you can insert a placeholder (`###IPADDRESS###`) in your config to be replaced (at POD creation time) with the actual IP address of the POD vernemq is running on, making VMQ clustering possible.

If istio is enabled you, set `DOCKER_VERNEMQ_KUBERNETES_ISTIO_ENABLED=1` so the init script will check if istio is ready.

### 5. Using [Docker Swarm](https://docs.docker.com/engine/swarm/)

Please follow the official Docker guide to properly setup Swarm cluster with one or more nodes.

Once Swarm is setup you can deploy a VerneMQ stack. The following snippet describes the stack using a `docker-compose.yml` file:

    version: "3.7"
    services:
      vmq0:
        image: vernemq/vernemq
        environment:
          DOCKER_VERNEMQ_SWARM: 1
      vmq:
        image: vernemq/vernemq
        depends_on:
          - vmq0
        environment:
          DOCKER_VERNEMQ_SWARM: 1
          DOCKER_VERNEMQ_DISCOVERY_NODE: vmq0
        deploy:
          replicas: 2

Run `docker stack deploy -c docker-compose.yml my-vernemq-stack` to deploy a 3 node VerneMQ cluster.

Note: Docker Swarm currently lacks the functionality similar to what is called a statefulset in Kubernetes. As a consequence VerneMQ must rely on a specific discovery service (the `vmq0` service above) that is started before the other replicas.

### Checking cluster status

To check if the above containers have successfully clustered you can issue the ```vmq-admin``` command:

    docker exec vernemq1 vmq-admin cluster show
    +--------------------+-------+
    |        Node        |Running|
    +--------------------+-------+
    |VerneMQ@172.17.0.151| true  |
    |VerneMQ@172.17.0.152| true  |
    +--------------------+-------+

If you started VerneMQ cluster inside Kubernetes using ```DOCKER_VERNEMQ_DISCOVERY_KUBERNETES=1```, you can execute ```vmq-admin``` through ```kubectl```:

    kubectl exec vernemq-0 -- vmq-admin cluster show
    +---------------------------------------------------+-------+
    |                       Node                        |Running|
    +---------------------------------------------------+-------+
    |VerneMQ@vernemq-0.vernemq.default.svc.cluster.local| true  |
    |VerneMQ@vernemq-1.vernemq.default.svc.cluster.local| true  |
    +---------------------------------------------------+-------+

All ```vmq-admin``` commands are available. See https://vernemq.com/docs/administration/ for more information.

### VerneMQ Configuration

All configuration parameters that are available in `vernemq.conf` can be defined
using the `DOCKER_VERNEMQ` prefix followed by the confguration parameter name.
E.g: `allow_anonymous=on` is `-e "DOCKER_VERNEMQ_ALLOW_ANONYMOUS=on"` or
`allow_register_during_netsplit=on` is
`-e "DOCKER_VERNEMQ_ALLOW_REGISTER_DURING_NETSPLIT=on"`. All available configuration
parameters can be found on https://vernemq.com/docs/configuration/.

#### Logging

VerneMQ store crash and error log files in `/var/log/vernemq/`, and, by default, 
doesn't write console log to the disk to avoid filling the container disk space.
However this behaviour can be changed by setting the environment variable `DOCKER_VERNEMQ_LOG__CONSOLE` to `both` 
which tells VerneMQ to send logs to stdout and `/var/log/vernemq/console.log`.
For more information please see VerneMQ logging documentation: https://docs.vernemq.com/configuring-vernemq/logging

#### Remarks

Some of our configuration variables contain dots `.`. For example if you want to
adjust the log level of VerneMQ you'd use `-e
"DOCKER_VERNEMQ_LOG.CONSOLE.LEVEL=debug"`. However, some container platforms
such as Kubernetes don't support dots and other special characters in
environment variables. If you are on such a platform you could substitute the
dots with two underscores `__`. The example above would look like `-e
"DOCKER_VERNEMQ_LOG__CONSOLE__LEVEL=debug"`.

There some some exceptions on configuration names contains dots. You can see follow examples:

format in vernemq.conf | format in environment variable name
---------------------- | ------------------------------------
 `vmq_webhooks.pool_timeout = 60000` | `DOCKER_VERNEMQ_VMQ_WEBHOOKS__POOL_timeout=6000`
 `vmq_webhooks.pool_timeout = 60000` | `DOCKER_VERNEMQ_VMQ_WEBHOOKS.pool_timeout=60000`


#### File Based Authentication

You can set up [File Based Authentication](https://vernemq.com/docs/configuration/authentication.html)
by adding users and passwords as environment variables as follows:

`DOCKER_VERNEMQ_USER_<USERNAME>='password'`

where `<USERNAME>` is the username you want to use. This can be done as many times as necessary
to create the users you want. The usernames will always be created in lowercase

*CAVEAT* - You cannot have a `=` character in your password.
