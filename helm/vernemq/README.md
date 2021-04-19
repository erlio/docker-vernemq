# VerneMQ

[VerneMQ](https://vernemq.com/) is a high-performance, distributed MQTT message broker. It scales
horizontally and vertically on commodity hardware to support a high number of
concurrent publishers and consumers while maintaining low latency and fault
tolerance. VerneMQ is the reliable message hub for your IoT platform or smart
products.

[VerneMQ](https://vernemq.com/) is an Apache2 licensed distributed MQTT broker, developed in Erlang.

## TL;DR;

```console
$ helm install vernemq/vernemq
```

## Introduction

This chart bootstraps a [VerneMQ](https://vernemq.com/) deployment on a [Kubernetes](https://kubernetes.io/) cluster using the [Helm](https://helm.sh/) package manager.

## Prerequisites

- Kubernetes 1.9, of 1.5 with Beta features enabled

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release vernemq/vernemq
```

The command deploys VerneMQ on the Kubernetes cluster in the default configuration. The configuration section lists the parameters that can be configured during installation.

> **Tip**: List all releases using helm list

## Uninstalling the Chart

To uninstall/delete the my-release deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the VerneMQ chart and their default values.

Parameter | Description | Default
--------- | ----------- | -------
`additionalEnv` | additional environment variables | see [values.yaml](values.yaml)
`envFrom` | additional envFrom configmaps or secrets | see [values.yaml](values.yaml)
`image.pullPolicy` | container image pull policy | `IfNotPresent`
`image.repository` | container image repository | `vernemq/vernemq`
`image.tag` | container image tag | the current versions (e.g. `1.11.0`)
`imagePullSecrets` | Image pull secrets for the Pod | `[]`
`ingress.enabled` | whether to enable an ingress object to route to the WebSocket service. Requires an ingress controller and the WebSocket service to be enabled. | `false`
`ingress.labels` | additional ingress labels | `{}`
`ingress.annotations` | additional service annotations | `{}`
`ingress.hosts` | a list of routable hostnames for host-based routing of traffic to the WebSocket service | `[]`
`ingress.paths` | a list of paths for path-based routing of traffic to the WebSocket service | `/`
`ingress.tls` | a list of TLS ingress configurations for securing the WebSocket ingress | `[]`
`nodeSelector` | node labels for pod assignment | `{}`
`persistentVolume.accessModes` | data Persistent Volume access modes | `[ReadWriteOnce]`
`persistentVolume.annotations` | annotations for Persistent Volume Claim | `{}`
`persistentVolume.enabled` | if true, create a Persistent Volume Claim | `true`
`persistentVolume.size` | data Persistent Volume size | `5Gi`
`persistentVolume.storageClass` | data Persistent Volume Storage Class | `unset`
`extraVolumeMounts` | Additional volumeMounts to the pod | `[]`
`extraVolumes` | Additional volumes to the pod | `[]`
`secretMounts` | mounts a secret as a file inside the statefulset. Useful for mounting certificates and other secrets.| `[]`
`podAntiAffinity` | pod anti affinity, `soft` for trying not to run pods on the same nodes, `hard` to force kubernetes not to run 2 pods on the same node | `soft`
`rbac.create` | if true, create & use RBAC resources | `true`
`rbac.serviceAccount.create` | if true, create a serviceAccount | `true`
`rbac.serviceAccount.name` | name of the service account to use or create | `{{ include "vernemq.fullname" . }}`
`replicaCount` | desired number of nodes | `1`
`resources` | resource requests and limits (YAML) | `{}`
`securityContext` | securityContext for containers in pod | `{}`
`service.annotations` | service annotations | `{}`
`service.clusterIP` | custom cluster IP when `service.type` is `ClusterIP` | `none`
`service.externalIPs` | optional service external IPs | `none`
`service.labels` | additional service labels | `{}`
`service.loadBalancerIP` | optional load balancer IP when `service.type` is `LoadBalancer` | `none`
`service.loadBalancerSourceRanges` | optional load balancer source ranges when `service.type` is `LoadBalancer` | `none`
`service.externalTrafficPolicy` | set this to `Local` to preserve client source IPs and prevent additional hops between K8s nodes if the service type is `LoadBalancer` or `NodePort` | `unset`
`service.sessionAffinity` | service session affinity | `none`
`service.sessionAffinityConfig` | service session affinity config | `none`
`service.mqtt.enabled` | whether to expose MQTT port | `true`
`service.mqtt.nodePort` | the MQTT port exposed by the node when `service.type` is `NodePort` | `1883`
`service.mqtt.port` | the MQTT port exposed by the service | `1883`
`service.mqtts.enabled` | whether to expose MQTTS port | `false`
`service.mqtts.nodePort` | the MQTTS port exposed by the node when `service.type` is `NodePort` | `8883`
`service.mqtts.port` | the MQTTS port exposed by the service | `8883`
`service.type` | type of service to create | `ClusterIP`
`service.ws.enabled` | whether to expose WebSocket port | `false`
`service.ws.nodePort` | the WebSocket port exposed by the node when `service.type` is `NodePort` | `8080`
`service.ws.port` | the WebSocket port exposed by the service | `8080`
`service.wss.enabled` | whether to expose secure WebSocket port | `false`
`service.wss.nodePort` | the secure WebSocket port exposed by the node when `service.type` is `NodePort` | `8443`
`service.wss.port` | the secure WebSocket port exposed by the service | `8443`
`statefulset.annotations` | additional annotations to the StatefulSet | `{}`
`statefulset.labels` | additional labels on the StatefulSet | `{}`
`statefulset.podAnnotations` | additional pod annotations | `{}`
`statefulset.podManagementPolicy` | start and stop pods in Parallel or OrderedReady (one-by-one.)  **Note** - Cannot change after first release. | `OrderedReady`
`statefulset.terminationGracePeriodSeconds` | configure how much time VerneMQ takes to move offline queues to other nodes | `60`
`statefulset.updateStrategy` | Statefulset updateStrategy | `RollingUpdate`
`statefulset.lifecycle` | Statefulset lifecycle hooks | `{}`
`serviceMonitor.create` | whether to create a ServiceMonitor for Prometheus Operator | `false`
`serviceMonitor.labels` | whether to add more labels to ServiceMonitor for Prometheus Operator | `{}`
`pdb.enabled` | whether to create a Pod Disruption Budget | `false`
`pdb.minAvailable` | PDB (min available) for the cluster | `1`
`pdb.maxUnavailable` | PDB (max unavailable) for the cluster | `nil`

Specify each parameter using the `--set key=value[,key=value]` argument to helm install. For example,

```console
$ helm install vernemq/vernemq --name my-release --set replicaCount=3
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm install vernemq/vernemq --name my-release -f values.yaml
```

> **Tip**: You can use the default [values.yaml](values.yaml)

### RBAC Configuration

Roles and RoleBindings resources will be created automatically.

To manually setup RBAC you need to set the parameter `rbac.create=false` and specify the service account to be used for each service by setting the parameters: `serviceAccounts.create` to `false` and `serviceAccounts.name` to the name of a pre-existing service account.

### Enable MQTTS

If you would like to enable MQTTS, follow these steps:

1. (a) Issue a certificate using Cert-Manager **OR** (b) Create secret resource using existing certificates.
2. Set the parameter `service.mqtts.enabled=true`.
3. Mount the certificate secret inside the statefulset.
4. Set the environment variables for the SSL listener.

#### (a) Issue a certificate using Cert-Manager
[Cert-Manager](https://github.com/jetstack/cert-manager) is a Kubernetes add-on. It can issue, renew and revoke a certificate from various issuing sources automatically. Cert-Manager obtains certificates from an ACME server (e.g., Let’s Encrypt) using ACME protocol.

You need to issue a new certificate. The issued certificate will be stored as secret `vernemq-certificates-secret` under the `default` namespace. The secret will be available to be mounted to the statefulset. See the example below:

```bash
cat <<EOF > vernemq-certificates.yaml
---
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: vernemq-certificates
  namespace: default
spec:
  secretName: vernemq-certificates-secret
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-staging
  commonName: mqtt.vernemq.com
  dnsNames:
  - mqtt.vernemq.com
  acme:
    config:
    - dns01:
        provider: digitalocean-dns
      domains:
      - mqtt.vernemq.com
EOF

kubectl apply -f vernemq-certificates.yaml
# output: certificate.certmanager.k8s.io/vernemq-certificates created
```

#### (b) Create secret resource using existing certificates

Using the key and crt files, you can create a secret. Kubernetes stores these files as a base64 string, so the first step is to encode them.

```bash
$ cat ca.crt| base64
LS0tLS1CRUdJTiBDRVJUSUZJQ...CBDRVJUSUZJQ0FURS0tLS0t
$ cat tls.crt | base64
LS0tLS1CRUdJTiBDRVJUSUZJQ...gQ0VSVElGSUNBVEUtLS0tLQo=
$ cat tls.key | base64
LS0tLS1CRUdJTiBSU0EgUFJJV...gUFJJVkFURSBLRVktLS0tLQo=
```

Now you can create a kubernetes resource definition (YAML) that will create the secret resource.

```bash
cat <<EOF > vernemq-certificates-secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: vernemq-certificates-secret
  namespace: default
type: kubernetes.io/tls
data:
  ca.crt:LS0tLS1CRUdJTiBDRVJUSUZJQ...CBDRVJUSUZJQ0FURS0tLS0t
  tls.crt:LS0tLS1CRUdJTiBDRVJUSUZJQ...gQ0VSVElGSUNBVEUtLS0tLQo=
  tls.key:LS0tLS1CRUdJTiBSU0EgUFJJV...gUFJJVkFURSBLRVktLS0tLQo=
EOF

kubectl apply -f vernemq-certificates-secret.yaml
# output: secret "vernemq-certificates-secret" created
```

#### Mount the certificate secret inside the statefulset

Inside `values.yaml` you can declared the mount path and the secret using the `secretMounts` parameter. For example:

```yaml
...
secretMounts:
  - name: vernemq-certificates
    secretName: vernemq-certificates-secret
    path: /etc/ssl/vernemq
...
```

#### Set the environment variables for the SSL listener

The exact path of the certificates can be declared inside `values.yaml` under `additionalEnv` parameter. For example:

```yaml
additionalEnv:
...
  - name: DOCKER_VERNEMQ_LISTENER__SSL__CAFILE
    value: "/etc/ssl/vernemq/tls.crt"
  - name: DOCKER_VERNEMQ_LISTENER__SSL__CERTFILE
    value: "/etc/ssl/vernemq/tls.crt"
  - name: DOCKER_VERNEMQ_LISTENER__SSL__KEYFILE
    value: "/etc/ssl/vernemq/tls.key"
...
```

> **Tip**: Cert-Manager includes both CA and TLS certificate in the `tls.crt` file.
