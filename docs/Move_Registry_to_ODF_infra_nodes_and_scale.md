# Move Registry to ODF, infra nodes and scale

Reference:
* [Infrastructure Nodes in OpenShift 4](https://access.redhat.com/solutions/5034771)
* [Configuring Image Registry to use OpenShift Container Storage](https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.8/html/managing_and_allocating_storage_resources/configure-storage-for-openshift-container-platform-services_rhocs#configuring-image-registry-to-use-openshift-container-storage_rhocs)
* [Moving the default registry](https://docs.openshift.com/container-platform/4.8/machine_management/creating-infrastructure-machinesets.html#infrastructure-moving-registry_creating-infrastructure-machinesets)


How to move the registry to ODF depends on where it is deployed. On bare metal it is usually waiting to be set up wither with empty dir (not production) or with a simple patch command to apply a create pvc.

As it is deployed here on AWS we will replace the current s3 config with our created pvc and also scale in one go:

## Check where pods running

```bash
<laptop-2>$ oc get po -n openshift-image-registry 
NAME                                               READY   STATUS      RESTARTS   AGE
cluster-image-registry-operator-696997c749-xrdwc   1/1     Running     0          17h
image-pruner-27292320-r8c64                        0/1     Completed   0          7h55m
image-registry-65bb859686-5l55f                    1/1     Running     0          20h
image-registry-65bb859686-nqs4k                    1/1     Running     0          20h
node-ca-7cltc                                      1/1     Running     1          20h
node-ca-b6qml                                      1/1     Running     1          20h
node-ca-f98zl                                      1/1     Running     1          20h
node-ca-pxjzd                                      1/1     Running     0          20h
node-ca-t7h59                                      1/1     Running     0          20h
<laptop-2>$ 
```

## Create a pvc based on ODF

```bash
<laptop-2>$ cat registry/01-restistry-storage-cephfs.yaml 
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: ocs4registry
  namespace: openshift-image-registry
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
  storageClassName: ocs-storagecluster-cephfs
<laptop-2>$
<laptop-2>$ oc create -f registry/01-restistry-storage-cephfs.yaml 
persistentvolumeclaim/ocs4registry created
<laptop-2>$ 
<laptop-2>$ oc get pvc -n openshift-image-registry
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                AGE
ocs4registry   Bound    pvc-18aa6089-b1af-45ac-bc97-8207d351efd1   100Gi      RWX            ocs-storagecluster-cephfs   8s
<laptop-2>$ 
```

## Create and replace config

Since we would need to remove the s3 part here with the created pvc, we can write a changed config and use ```**replace**``` instead of ```apply``` .

```bash
<laptop-2>$ cat registry/02-registry-config.yaml 
apiVersion: imageregistry.operator.openshift.io/v1
kind: Config
metadata:
  name: cluster
spec:
  logLevel: Normal
  managementState: Managed
  operatorLogLevel: Normal
  nodeSelector:
    node-role.kubernetes.io/infra: ""
  proxy: {}
  replicas: 3
  requests:
    read:
      maxWaitInQueue: 0s
    write:
      maxWaitInQueue: 0s
  rolloutStrategy: RollingUpdate
  storage:
    pvc:
      claim: ocs4registry

<laptop-2>$ 
<laptop-2>$ oc replace -f registry/02-registry-config.yaml
config.imageregistry.operator.openshift.io/cluster replaced
<laptop-2>$ 
```

## Validate change

```bash
<laptop-2>$ oc get configs.imageregistry.operator.openshift.io/cluster -o json |jq .spec
{
  "httpSecret": "f81c577d397a9660d04541c65dbf0fc31666f8721b410962b39db3b089b889ea371833db16365df17a28ddb6a6835d6cfa7523b45e096109c82c75c45564fda8",
  "logLevel": "Normal",
  "managementState": "Managed",
  "nodeSelector": {
    "node-role.kubernetes.io/infra": ""
  },
  "observedConfig": null,
  "operatorLogLevel": "Normal",
  "proxy": {},
  "replicas": 3,
  "requests": {
    "read": {
      "maxWaitInQueue": "0s"
    },
    "write": {
      "maxWaitInQueue": "0s"
    }
  },
  "rolloutStrategy": "RollingUpdate",
  "storage": {
    "managementState": "Unmanaged",
    "pvc": {
      "claim": "ocs4registry"
    }
  },
  "unsupportedConfigOverrides": null
}
<laptop-2>$ 
```

## Check where pods are running

```bash
<laptop-2>$ oc get po -n openshift-image-registry 
NAME                                               READY   STATUS    RESTARTS   AGE
cluster-image-registry-operator-696997c749-mfhhv   1/1     Running   0          2m3s
image-registry-777dc54966-59w4s                    1/1     Running   0          2m3s
image-registry-777dc54966-d4f6b                    1/1     Running   0          2m3s
image-registry-777dc54966-rgdbg                    1/1     Running   0          2m3s
node-ca-4md6g                                      1/1     Running   0          117s
node-ca-fjwzp                                      1/1     Running   0          2m1s
node-ca-kjp7n                                      1/1     Running   0          116s
node-ca-tx7lt                                      1/1     Running   0          2m
node-ca-wrznn                                      1/1     Running   0          2m
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ oc get po -n openshift-image-registry -o wide |egrep -v $CP_NODES
NAME                                               READY   STATUS    RESTARTS   AGE    IP             NODE                                         NOMINATED NODE   READINESS GATES
node-ca-kjp7n                                      1/1     Running   0          118s   10.0.177.190   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
node-ca-tx7lt                                      1/1     Running   0          2m2s   10.0.148.134   ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
<laptop-2>$ 
```

components are now running on infra nodes apart from ```*-ca-*``` pods which are supposed to run on every node.

In the next step we will [move OpenShift monitoring to infra nodes](Move_monitoring_to_infra_nodes_and_ODF.md)
