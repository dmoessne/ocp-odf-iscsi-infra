# Deploy ODF

References:
* [Install Red Hat OpenShift Container Storage 4.X in internal-attached mode using command line interface. - Red Hat Customer Portal](https://access.redhat.com/articles/5692201#overview-1)
* [Creating OpenShift Container Storage cluster on bare metal](https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.8/html/deploying_openshift_container_storage_using_bare_metal_infrastructure/deploy-using-local-storage-devices-bm#creating-openshift-container-storage-cluster-on-bare-metal_rhocs)
* [Verifying OpenShift Container Storage deployment](https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.8/html/deploying_openshift_container_storage_using_bare_metal_infrastructure/verifying-openshift-container-storage-deployment_rhocs)


Since we do have now LSO running providing us with local block volumes we can deploy ODF as follows.

Again, this is based on [Install Red Hat OpenShift Container Storage 4.X in internal-attached mode using command line interface. - Red Hat Customer Portal](https://access.redhat.com/articles/5692201#overview-1) and files can be found in folder `ocs`

**Mind**:

* if you want to use the files provided, make sure they fit to your setup, esp disk sizes in `09-StorageCluster-ocs-storagecluster.yaml`

## Relevant folder content

```bash
<laptop-2>$ ls -l ocs/
total 44
[...]
-rw-rw-r--. 1 dm dm  127 Nov 21 11:39 06-Namespace-openshift-storage.yaml
-rw-rw-r--. 1 dm dm  481 Nov 21 11:39 07-Subscription-ocs-operator.yaml
-rw-rw-r--. 1 dm dm  181 Nov 21 11:39 08-OperatorGroup-openshift-storage-operatorgroup.yaml
-rw-rw-r--. 1 dm dm 1029 Nov 21 11:39 09-StorageCluster-ocs-storagecluster.yaml
<laptop-2>$ 
```

### Create namespace, Operatorgroup (og) and Subscription (subs)

**Mind** ODF namespace ```openshift-storage``` needs annotation ```openshift.io/node-selector: ""``` in order to work properly with our changed default node selector later on.
Otherwise ODF pods will not get rescheduled, e.g in case of an upgrade

```bash
<laptop-2>$ cat ocs/06-Namespace-openshift-storage.yaml
apiVersion: v1
kind: Namespace
metadata:
 annotations:
    openshift.io/node-selector: ""
 labels:
   openshift.io/cluster-monitoring: "true"
 name: openshift-storage
spec: {}
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ oc create -f ocs/06-Namespace-openshift-storage.yaml
namespace/openshift-storage created
<laptop-2>$ 
<laptop-2>$ oc get namespace openshift-storage
NAME                STATUS   AGE
openshift-storage   Active   9s
<laptop-2>$ 
<laptop-2>$ cat ocs/07-Subscription-ocs-operator.yaml 
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
 name: ocs-operator
 namespace: openshift-storage
spec:
 channel: "stable-4.8"  # <-- Channel should be modified depending on the OCS version to be installed. Please ensure to maintain compatibility with OCP version
 installPlanApproval: Automatic
 name: ocs-operator
 source: redhat-operators  # <-- Modify the name of the redhat-operators catalogsource if not default
 sourceNamespace: openshift-marketplace
<laptop-2>$ 
<laptop-2>$ oc create -f ocs/07-Subscription-ocs-operator.yaml 
subscription.operators.coreos.com/ocs-operator created
<laptop-2>$ 
<laptop-2>$ cat ocs/08-OperatorGroup-openshift-storage-operatorgroup.yaml 
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
 name: openshift-storage-operatorgroup
 namespace: openshift-storage
spec:
 targetNamespaces:
 - openshift-storage
<laptop-2>$ 
<laptop-2>$ oc create -f ocs/08-OperatorGroup-openshift-storage-operatorgroup.yaml 
operatorgroup.operators.coreos.com/openshift-storage-operatorgroup created
<laptop-2>$ 
```

### Check og, subs and pods are running

Before progressing, we want to make sure og, subs and pods are there and running

```bash
<laptop-2>$ oc get subs,og -n openshift-storage 
NAME                                             PACKAGE        SOURCE             CHANNEL
subscription.operators.coreos.com/ocs-operator   ocs-operator   redhat-operators   stable-4.8

NAME                                                                 AGE
operatorgroup.operators.coreos.com/openshift-storage-operatorgroup   50s
<laptop-2>$ 
<laptop-2>$ oc get po -n openshift-storage 
NAME                                   READY   STATUS    RESTARTS   AGE
noobaa-operator-7c78b8cb89-h2d9d       1/1     Running   0          28s
ocs-metrics-exporter-9cf6d7f54-qd942   1/1     Running   0          28s
ocs-operator-648946bb-4z74f            1/1     Running   0          28s
rook-ceph-operator-54cd89f569-f9fmc    1/1     Running   0          28s
<laptop-2>$ 
```

## Deploy StorageCluster

Once confirmed operator and metric exporter pods are running, we can deploy the Storagecluster.

**Mind**: Make sure the disk size, ```storage``` matches yours. As this is a minimal disk size we have chosen a bit of a smaller size (999Gi) than the actual size, which is 1024Gib.

```bash
<laptop-2>$ vim ocs/09-StorageCluster-ocs-storagecluster.yaml 
<laptop-2>$ cat ocs/09-StorageCluster-ocs-storagecluster.yaml 
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  name: ocs-storagecluster
  namespace: openshift-storage
spec:
  encryption:  # <-- Add this option to enable the encryption in the OCS cluster 
    enable: true
  manageNodes: false
  resources:
    mds:
      limits:
        cpu: "3"
        memory: "8Gi"
      requests:
        cpu: "3"
        memory: "8Gi"
  monDataDirHostPath: /var/lib/rook
  storageDeviceSets:
  - count: 1  # <-- Modify count to desired value. For each set of 3 disks increment the count by 1.
    dataPVCTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: "999Gi"  # <-- This should be changed as per storage size. Minimum 100 GiB and Maximum 4 TiB
        storageClassName: localblock
        volumeMode: Block
    name: ocs-deviceset
    placement: {}
    portable: false
    replica: 3
    resources:
      limits:
        cpu: "2"
        memory: "5Gi"
      requests:
        cpu: "2"
        memory: "5Gi"
<laptop-2>$ 
<laptop-2>$ oc create -f ocs/09-StorageCluster-ocs-storagecluster.yaml
storagecluster.ocs.openshift.io/ocs-storagecluster created
<laptop-2>$ 
```

## watch deployment

It lasts some time until all the components are up and running. This cat be watched with ```oc get po -w -n openshift-storage``` or ```watch -n 20 oc get po -n openshift-storage```

```bash
<laptop-2>$ oc get po -n openshift-storage 
NAME                                   READY   STATUS            RESTARTS   AGE
noobaa-operator-7c78b8cb89-h2d9d       1/1     Running           0          77s
ocs-metrics-exporter-9cf6d7f54-qd942   1/1     Running           0          77s
ocs-operator-648946bb-4z74f            1/1     Running           0          77s
rook-ceph-detect-version-sk4zs         0/1     PodInitializing   0          4s
rook-ceph-operator-54cd89f569-f9fmc    1/1     Running           0          77s
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ oc get po -n openshift-storage 
NAME                                           READY   STATUS              RESTARTS   AGE
csi-cephfsplugin-7gn9f                         0/3     ContainerCreating   0          11s
csi-cephfsplugin-96mcs                         0/3     ContainerCreating   0          11s
csi-cephfsplugin-br5hl                         0/3     ContainerCreating   0          11s
csi-cephfsplugin-jfnc5                         0/3     ContainerCreating   0          11s
csi-cephfsplugin-provisioner-7dc5f4db4-7skgn   0/6     ContainerCreating   0          11s
csi-cephfsplugin-provisioner-7dc5f4db4-q9w5p   0/6     ContainerCreating   0          11s
csi-cephfsplugin-zkj48                         0/3     ContainerCreating   0          11s
csi-rbdplugin-2gxzs                            0/3     ContainerCreating   0          12s
csi-rbdplugin-84q7h                            0/3     ContainerCreating   0          12s
csi-rbdplugin-dhvlm                            0/3     ContainerCreating   0          12s
csi-rbdplugin-kd482                            0/3     ContainerCreating   0          12s
csi-rbdplugin-provisioner-6f4cc98cdf-5pvcb     0/6     ContainerCreating   0          12s
csi-rbdplugin-provisioner-6f4cc98cdf-snhwg     0/6     ContainerCreating   0          12s
csi-rbdplugin-szfp7                            0/3     ContainerCreating   0          12s
noobaa-operator-7c78b8cb89-h2d9d               1/1     Running             0          89s
ocs-metrics-exporter-9cf6d7f54-qd942           1/1     Running             0          89s
ocs-operator-648946bb-4z74f                    1/1     Running             0          89s
rook-ceph-mon-a-56cc6dc596-qg5c5               0/2     Pending             0          3s
rook-ceph-mon-a-canary-5cfc486f9b-zxj86        0/2     Terminating         0          6s
rook-ceph-operator-54cd89f569-f9fmc            1/1     Running             0          89s
<laptop-2>$ 
```

## Validate install

After some times all pods are up an running. Check all pods are up and running and show the same numbers in ```READY```, e.g. ```3/3```

### Validate pods

```bash
<laptop-2>$ oc get po -n openshift-storage 
NAME                                                              READY   STATUS      RESTARTS   AGE
csi-cephfsplugin-7gn9f                                            3/3     Running     0          6m23s
csi-cephfsplugin-96mcs                                            3/3     Running     0          6m23s
csi-cephfsplugin-br5hl                                            3/3     Running     0          6m23s
csi-cephfsplugin-jfnc5                                            3/3     Running     0          6m23s
csi-cephfsplugin-provisioner-7dc5f4db4-7skgn                      6/6     Running     0          6m23s
csi-cephfsplugin-provisioner-7dc5f4db4-q9w5p                      6/6     Running     0          6m23s
csi-cephfsplugin-zkj48                                            3/3     Running     0          6m23s
csi-rbdplugin-2gxzs                                               3/3     Running     0          6m24s
csi-rbdplugin-84q7h                                               3/3     Running     0          6m24s
csi-rbdplugin-dhvlm                                               3/3     Running     0          6m24s
csi-rbdplugin-kd482                                               3/3     Running     0          6m24s
csi-rbdplugin-provisioner-6f4cc98cdf-5pvcb                        6/6     Running     0          6m24s
csi-rbdplugin-provisioner-6f4cc98cdf-snhwg                        6/6     Running     0          6m24s
csi-rbdplugin-szfp7                                               3/3     Running     0          6m24s
noobaa-core-0                                                     1/1     Running     0          4m51s
noobaa-db-pg-0                                                    1/1     Running     0          4m51s
noobaa-endpoint-86d64f4dcc-9mxc6                                  1/1     Running     0          2m53s
noobaa-operator-7c78b8cb89-h2d9d                                  1/1     Running     0          7m41s
ocs-metrics-exporter-9cf6d7f54-qd942                              1/1     Running     0          7m41s
ocs-operator-648946bb-4z74f                                       1/1     Running     0          7m41s
rook-ceph-crashcollector-ip-10-0-157-223-7d457db799-bjgs4         1/1     Running     0          4m52s
rook-ceph-crashcollector-ip-10-0-173-122-7d969d46c7-j6g58         1/1     Running     0          4m36s
rook-ceph-crashcollector-ip-10-0-206-223-564fcbdf4-x6crm          1/1     Running     0          4m37s
rook-ceph-mds-ocs-storagecluster-cephfilesystem-a-8cffd688g885x   2/2     Running     0          4m37s
rook-ceph-mds-ocs-storagecluster-cephfilesystem-b-7d848fbcc8dbn   2/2     Running     0          4m36s
rook-ceph-mgr-a-5fdf6674fd-gltcb                                  2/2     Running     0          5m23s
rook-ceph-mon-a-56cc6dc596-qg5c5                                  2/2     Running     0          6m15s
rook-ceph-mon-b-6d9d7648d4-k2bch                                  2/2     Running     0          5m48s
rook-ceph-mon-c-54f95796dd-tfllz                                  2/2     Running     0          5m37s
rook-ceph-operator-54cd89f569-f9fmc                               1/1     Running     0          7m41s
rook-ceph-osd-0-6d7b5895f9-xnzx7                                  2/2     Running     0          4m53s
rook-ceph-osd-1-566c44b8bc-s9pnk                                  2/2     Running     0          4m52s
rook-ceph-osd-2-647b6c68dc-h4tqv                                  2/2     Running     0          4m52s
rook-ceph-osd-prepare-ocs-deviceset-0-data-0sz5gq-mztnm           0/1     Completed   0          5m17s
rook-ceph-osd-prepare-ocs-deviceset-1-data-0qcc8t-85xg4           0/1     Completed   0          5m17s
rook-ceph-osd-prepare-ocs-deviceset-2-data-0fqsbv-hqfmn           0/1     Completed   0          5m16s
<laptop-2>$ 
```

It is expected that ```rook-ceph-osd-prepare-ocs-deviceset-*``` are be ```Completed``` as their purpose is to prepare the disks for OSDs

### Validate storage- and cephcluster

```bash
<laptop-2>$ 
<laptop-2>$ oc get storagecluster -n openshift-storage
NAME                 AGE     PHASE   EXTERNAL   CREATED AT             VERSION
ocs-storagecluster   6m41s   Ready              2021-11-21T15:17:57Z   4.8.0
<laptop-2>$ 
<laptop-2>$ oc get cephcluster -n openshift-storage
NAME                             DATADIRHOSTPATH   MONCOUNT   AGE     PHASE   MESSAGE                        HEALTH      EXTERNAL
ocs-storagecluster-cephcluster   /var/lib/rook     3          6m53s   Ready   Cluster created successfully   HEALTH_OK   
<laptop-2>$ 
<laptop-2>$ 
```

### validate nodes

Finally, let's check all pods are running on the master nodes

```bash
<laptop-2>$ CP_NODES=`oc get nodes -l node-role.kubernetes.io/master= |awk '/master/ {print $1}'|tr '\n' '|' |sed 's/|$//g'`
<laptop-2>$ 
<laptop-2>$ oc get po -o wide -n openshift-local-storage |egrep -v $CP_NODES
NAME                                      READY   STATUS    RESTARTS   AGE   IP            NODE                                         NOMINATED NODE   READINESS GATES
<laptop-2>$ oc get po -o wide -n openshift-storage |egrep -v $CP_NODES
NAME                                                              READY   STATUS      RESTARTS   AGE   IP             NODE                                         NOMINATED NODE   READINESS GATES
csi-cephfsplugin-7gn9f                                            3/3     Running     0          26m   10.0.148.134   ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
csi-cephfsplugin-br5hl                                            3/3     Running     0          26m   10.0.177.190   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
csi-rbdplugin-2gxzs                                               3/3     Running     0          26m   10.0.177.190   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
csi-rbdplugin-szfp7                                               3/3     Running     0          26m   10.0.148.134   ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
<laptop-2>$ 
```

Those ```csi-*``` pods are expected to run on the workers so we can mount volumes.

This concludes the LSO/ODF installationnd we can continue with [creating infra nodes and chanching the default scheduler](Create_infra_nodes_masters_and_change_default_scheduler.md)
