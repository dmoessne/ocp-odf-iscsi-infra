## Deploying LSO backed ODF on top of unschedulable control plane nodes (masters)

The procedure outlined here is best to my knowledge not officially supported as of yet. However a RFE will be filed to get validated if full support could be provided.

# WIP

### Versioning
* first draft

### Abstract

The goal of the following procedure is to install LSO backed ODF on top of 3 control plane nodes (fka masters) which are not marked schedulable to avoid the need for changing the default scheduler (mind limitations at the top level Readme).

Some customer are deploying OCP and ODF on top of their standardized hardware which is often hard to change and has more than sufficient resources to run ODF on top of the control plane nodes as well.

This way control plane nodes get better utilized while worker nodes have more resources for custom workload. (A further evolution of this might be to also move (parts) of additional infra components like router, monitoring or logging to those control plane nodes)

Some remarks about findings when working on this:

* Reference:
  
  * [1] [rook/ceph-cluster-crd.md at master · red-hat-storage/rook · GitHub](https://github.com/red-hat-storage/rook/blob/master/Documentation/ceph-cluster-crd.md)
    
  * [Install Red Hat OpenShift Container Storage 4.X in internal-attached mode using command line interface. - Red Hat Customer Portal](https://access.redhat.com/articles/5692201)
    
  
* Binding Operators and Subscription to tainted nodes:
  
  * OperatorGroups seem not to be able to get taints added to it according to [operator-lifecycle-manager/operatorgroups.md at master · operator-framework/operator-lifecycle-manager · GitHub](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/doc/design/operatorgroups.md)
    
  * In order to get Operators scheduled on control plane nodes anyway, namespaces got tolerations added as well as labels for affinity
    

**Files used to create this setup can be found in this folder as well, however for the sake of explaining they will be posted here as well annotated for clarity.**

### Setup

For simplicity this setup was build on top of AWS with 3 masters (control plane nodes) with directly added disks for LSO and 3 additional worker nodes:

### Label control plane nodes

For ODF deployment we first of all label the master nodes with label `cluster.ocs.openshift.io/openshift-storage=""` :

```bash
$ oc label -l node-role.kubernetes.io/master nodes cluster.ocs.openshift.io/openshift-storage=""
node/ip-10-0-130-232.us-west-2.compute.internal labeled
node/ip-10-0-190-243.us-west-2.compute.internal labeled
node/ip-10-0-206-139.us-west-2.compute.internal labeled
$ 
$ oc get nodes -l node-role.kubernetes.io/master
NAME                                         STATUS   ROLES    AGE   VERSION
ip-10-0-130-232.us-west-2.compute.internal   Ready    master   92m   v1.21.1+a620f50
ip-10-0-190-243.us-west-2.compute.internal   Ready    master   93m   v1.21.1+a620f50
ip-10-0-206-139.us-west-2.compute.internal   Ready    master   94m   v1.21.1+a620f50
$ 
```

### Create and configure LSO

#### Create namespace, Operatorgroup and subscription

As outlined above the namespace will be annotated and labeled so that Operators are bound to master nodes:

```yaml
$ cat 01-Namespace-openshift-local-storage.yaml 
apiVersion: v1
kind: Namespace
metadata:
 name: openshift-local-storage
spec:
  selector:
    matchLabels:  # <- bind to certain labels
      cluster.ocs.openshift.io/openshift-storage: ""
      node-role.kubernetes.io/master: ""
    tolerations: # <- tolerate master taints 
    - effect: NoSchedule
      key: node-role.kubernetes.io/master
      effect: Equal
      value: ''

$ cat 02-OperatorGroup-local-operator-group.yaml 
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
 name: local-operator-group
 namespace: openshift-local-storage
spec:
 targetNamespaces:
 - openshift-local-storage
 selector:  # <- bind to certain labels
    matchLabels: 
      cluster.ocs.openshift.io/openshift-storage: ""
      node-role.kubernetes.io/master: ""
$ 
$ cat 03-Subscription-local-storage-operator.yaml 
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
 name: local-storage-operator
 namespace: openshift-local-storage
spec:
 channel: "4.8"  # <-- Channel should be used corresponding to the OCP version being used.
 config:
   tolerations: # <- tolerate master taints
   - effect: NoSchedule
     key: node-role.kubernetes.io/master
     operator: Equal
     value: ''
 installPlanApproval: Automatic
 name: local-storage-operator
 source: redhat-operators  # <-- Modify the name of the redhat-operators catalogsource if not default
 sourceNamespace: openshift-marketplace
$ 
```

```bash
$ oc create -f 01-Namespace-openshift-local-storage.yaml -f 02-OperatorGroup-local-operator-group.yaml -f 03-Subscription-local-storage-operator.yaml 
namespace/openshift-local-storage created
operatorgroup.operators.coreos.com/local-operator-group created
subscription.operators.coreos.com/local-storage-operator created
```

#### Validate Operator is deployed

```bash
$ oc project openshift-local-storage
Now using project "openshift-local-storage" on server "https://api.dmoessne.emeatam.support:6443".
$ 
$ oc get pod,og,subs
NAME                                          READY   STATUS    RESTARTS   AGE
pod/local-storage-operator-79878bbc6b-lrzp7   1/1     Running   0          24s

NAME                                                      AGE
operatorgroup.operators.coreos.com/local-operator-group   94s

NAME                                                       PACKAGE                  SOURCE             CHANNEL
subscription.operators.coreos.com/local-storage-operator   local-storage-operator   redhat-operators   4.8
$ 
```

#### Create LocalVolume

Once the operator `local-storage-operator-*` is running we can deploy LocalStorage. Here as well selectors and tolerations are added

```yaml
$ cat 04-05-LocalVolume-local-block.yaml 
apiVersion: local.storage.openshift.io/v1
kind: LocalVolume
metadata:
  name: local-block-masters
  namespace: openshift-local-storage
spec:
  nodeSelector: # <- bind to certain nodes 
    nodeSelectorTerms:
    - matchExpressions:
        - key: node-role.kubernetes.io/master
          operator: Exists
  tolerations:  # <- tolerate master taints
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
    operator: Equal
    value: ''
  storageClassDevices:
    - storageClassName: local-block-master # <--- needed in the next steps
      volumeMode: Block
      devicePaths:
        - /dev/nvme1n1 # <- mind this is direct attached disk, change to your path accordingly and mind this works only if disk names are the same on every node, else you'd need to specify multiple paths
$ 
```

```bash
$ oc create -f 04-05-LocalVolume-local-block.yaml
localvolume.local.storage.openshift.io/local-block-masters created
```

#### Verify local volume PVs have been created

```bash
$ oc get po
NAME                                      READY   STATUS    RESTARTS   AGE
diskmaker-manager-7ddkz                   1/1     Running   0          36s
diskmaker-manager-ghszh                   1/1     Running   0          36s
diskmaker-manager-v6q2n                   1/1     Running   0          36s
local-storage-operator-79878bbc6b-lrzp7   1/1     Running   0          2m50s
$ 
$ oc get sc 
NAME                 PROVISIONER                    RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
gp2 (default)        kubernetes.io/aws-ebs          Delete          WaitForFirstConsumer   true                   99m
gp2-csi              ebs.csi.aws.com                Delete          WaitForFirstConsumer   true                   99m
local-block-master   kubernetes.io/no-provisioner   Delete          WaitForFirstConsumer   false                  2m30s
$ 
$ oc get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS         REASON   AGE
local-pv-66adc0a1   1Ti        RWO            Delete           Available           local-block-master            80s
local-pv-b7fbb8be   1Ti        RWO            Delete           Available           local-block-master            84s
local-pv-c03eb61b   1Ti        RWO            Delete           Available           local-block-master            80s
$ 
```

### Deploy ODF on top

Now that LSO is deployed successfully and we do have PVs which are ready to be consumed we can start deploying ODF.

#### Create Namespace, subscription and Operatorgroup

```yaml
$ cat 06-Namespace-openshift-storage.yaml 
apiVersion: v1
kind: Namespace
metadata:
 annotations:
    openshift.io/node-selector: ""
 labels:
   openshift.io/cluster-monitoring: "true"
 name: openshift-storage
spec: 
  selector:
    matchLabels:
      cluster.ocs.openshift.io/openshift-storage: ""
      node-role.kubernetes.io/master: ""
    tolerations:
    - effect: NoSchedule
      key: node-role.kubernetes.io/master
      effect: Equal
      value: ''
$ 
$ cat 07-Subscription-ocs-operator.yaml 
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
 name: ocs-operator
 namespace: openshift-storage
spec:
 channel: "stable-4.8"  # <-- Channel should be modified depending on the OCS version to be installed. Please ensure to maintain compatibility with OCP version
 config:
   tolerations:
   - effect: NoSchedule
     key: node-role.kubernetes.io/master
     operator: Equal
     value: ''
 installPlanApproval: Automatic
 name: ocs-operator
 source: redhat-operators  # <-- Modify the name of the redhat-operators catalogsource if not default
 sourceNamespace: openshift-marketplace
$ 
$ cat 08-OperatorGroup-openshift-storage-operatorgroup.yaml 
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
 name: openshift-storage-operatorgroup
 namespace: openshift-storage
spec:
 selector:
    matchLabels: # <- bind according to selector
      cluster.ocs.openshift.io/openshift-storage: ""
      node-role.kubernetes.io/master: ""
 targetNamespaces:
 - openshift-storage
$ 
```

```bash
$ oc create -f 06-Namespace-openshift-storage.yaml -f 07-Subscription-ocs-operator.yaml -f 08-OperatorGroup-openshift-storage-operatorgroup.yaml
namespace/openshift-storage created
subscription.operators.coreos.com/ocs-operator created
operatorgroup.operators.coreos.com/openshift-storage-operatorgroup created
```

#### Validate successful creation

```bash
$ oc project openshift-storage
Now using project "openshift-storage" on server "https://api.dmoessne.emeatam.support:6443".
$ 
$ oc get pod,og,subs
NAME                                                                 AGE
operatorgroup.operators.coreos.com/openshift-storage-operatorgroup   20s

NAME                                             PACKAGE        SOURCE             CHANNEL
subscription.operators.coreos.com/ocs-operator   ocs-operator   redhat-operators   stable-4.8
$ 
$ 
$ oc get pod,og,subs
NAME                                        READY   STATUS    RESTARTS   AGE
pod/noobaa-operator-7d59fb884d-zkt6t        1/1     Running   0          105s
pod/ocs-metrics-exporter-855cfcbc99-hrqxn   1/1     Running   0          105s
pod/ocs-operator-64c646957-p94bh            1/1     Running   0          105s
pod/rook-ceph-operator-5975ddcfb6-cdp8r     1/1     Running   0          105s

NAME                                                                 AGE
operatorgroup.operators.coreos.com/openshift-storage-operatorgroup   2m27s

NAME                                             PACKAGE        SOURCE             CHANNEL
subscription.operators.coreos.com/ocs-operator   ocs-operator   redhat-operators   stable-4.8
$ 
```

#### Alter CSI Tolerations

Before we go ahead and deploy the `StorageCluster` as well, to ensure `CSI_PLUGIN_TOLERATIOS` and `CSI_PROVISIONER_TOLERATIONS` are able to be scheduled on the control plane nodes, i.e. accept tolerate the taints, ConfigMap `rook-ceph-operator-config` needs to be altered.

Per default it looks like :

```yaml
$ oc get -o yaml cm rook-ceph-operator-config
apiVersion: v1
data:
  CSI_LOG_LEVEL: "5"
  CSI_PLUGIN_TOLERATIONS: |2-

    - key: node.ocs.openshift.io/storage
      operator: Equal
      value: "true"
      effect: NoSchedule
  CSI_PROVISIONER_TOLERATIONS: |2-

    - key: node.ocs.openshift.io/storage
      operator: Equal
      value: "true"
      effect: NoSchedule
kind: ConfigMap
metadata:
  creationTimestamp: "2021-12-08T07:55:28Z"
  name: rook-ceph-operator-config
  namespace: openshift-storage
  resourceVersion: "64038"
  uid: 636f46b2-f75d-4892-ad7a-f3ef359e4304
$ 
```

And to tolerate master taints, we need to alter as follows:

```yaml
$ cat 09-rook-ceph-operator-config.yaml 
apiVersion: v1
data:
  CSI_LOG_LEVEL: "5"
  CSI_PLUGIN_TOLERATIONS: |2-

    - key: node-role.kubernetes.io/master
      operator: Equal
      value: ''
      effect: NoSchedule
  CSI_PROVISIONER_TOLERATIONS: |2-

    - key: node-role.kubernetes.io/master
      operator: Equal
      value: ''
      effect: NoSchedule
kind: ConfigMap
metadata:
  name: rook-ceph-operator-config
  namespace: openshift-storage
$ 
```

Either edit the cm directly or apply the changed by using `oc replace`:

```bash
$ oc replace -f 09-rook-ceph-operator-config.yaml 
configmap/rook-ceph-operator-config replaced
$ 
```

Once that got applied, you should the `*-provisioner-*` pods moving to masters.

#### Create StorageCluster itself

In order to get the StorageCluster deployed in a way all components are running on master nodes only (apart csi pods which we need on nodes to get storage mounted) we need to add additional section to the yaml:

```yaml
$ cat 10-StorageCluster-ocs-storagecluster.yaml 
apiVersion: ocs.openshift.io/v1
kind: StorageCluster
metadata:
  name: ocs-storagecluster
  namespace: openshift-storage
spec:
  placement:
    all:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: cluster.ocs.openshift.io/openshift-storage
                  operator: Exists
                - key: node-role.kubernetes.io/master
                  operator: Exists
      tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
          operator: Equal
          value: ''
    mds:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: cluster.ocs.openshift.io/openshift-storage
              operator: Exists
            - key: node-role.kubernetes.io/master
              operator: Exists
      tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
          operator: Equal
          value: ''
    noobaa-core:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: cluster.ocs.openshift.io/openshift-storage
              operator: Exists
            - key: node-role.kubernetes.io/master
              operator: Exists
      tolerations:
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
        operator: Equal
        value: ''
  manageNodes: true
  encryption:  # <-- Add this option to enable the encryption in the OCS cluster 
    enable: false
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
        storageClassName: local-block-master
        volumeMode: Block
    name: ocs-deviceset
    placement: 
      osd: 
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: cluster.ocs.openshift.io/openshift-storage
                    operator: Exists
                  - key: node-role.kubernetes.io/master
                    operator: Exists
        tolerations: 
          - effect: NoSchedule
            key: node-role.kubernetes.io/master
            operator: Equal
            value: ''
    portable: false
    replica: 3
    resources: {}
$ 

```

##### Additions explained

###### placement: all

```yaml
    all:
      nodeAffinity:  # <- schedule nodes on top of accordingly labeled nodes
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: cluster.ocs.openshift.io/openshift-storage
                  operator: Exists
                - key: node-role.kubernetes.io/master
                  operator: Exists
      tolerations: # <- add tolarations for master nodes
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
          operator: Equal
          value: ''
```

See [rook/ceph-cluster-crd.md at master · red-hat-storage/rook · GitHub](https://github.com/red-hat-storage/rook/blob/master/Documentation/ceph-cluster-crd.md#placement-configuration-settings) for details

Includes the following keys: `mgr`, `mon`, `arbiter`, `osd`, `cleanup`, and `all` Each service will have its placement configuration generated by merging the generic configuration under `all` with the most specific one (which will override any attributes).

Additional components, like `mds` and `noobaa` we need to add additional sections. For `osd` please mind that placement of OSD pods is controlled using the `StorageDeviceSet` section, not the general placement configuration.

###### placement for mds and noobaa

```yaml
    mds:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: cluster.ocs.openshift.io/openshift-storage
              operator: Exists
            - key: node-role.kubernetes.io/master
              operator: Exists
      tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
          operator: Equal
          value: ''
    noobaa-core:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: cluster.ocs.openshift.io/openshift-storage
              operator: Exists
            - key: node-role.kubernetes.io/master
              operator: Exists
      tolerations:
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
        operator: Equal
        value: ''
```

Basically following the same rules with regards to selectors and tolerations

###### placement OSD

As stated above, `osd` is a separate section in `StorageDeviceSet`:

```yaml
  storageDeviceSets:
[...]
    name: ocs-deviceset
    placement: 
      osd: 
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: cluster.ocs.openshift.io/openshift-storage
                    operator: Exists
                  - key: node-role.kubernetes.io/master
                    operator: Exists
        tolerations: 
          - effect: NoSchedule
            key: node-role.kubernetes.io/master
            operator: Equal
            value: ''
```

##### Create Storagecluster and validate

```bash
$ oc create -f 10-StorageCluster-ocs-storagecluster.yaml 
storagecluster.ocs.openshift.io/ocs-storagecluster created
```

After some time we should have a fully running cluster

```bash
$ oc get po 
NAME                                                              READY   STATUS      RESTARTS   AGE
csi-cephfsplugin-bq5cg                                            3/3     Running     0          6m25s
csi-cephfsplugin-cg2cp                                            3/3     Running     0          6m25s
csi-cephfsplugin-cwbhw                                            3/3     Running     0          6m25s
csi-cephfsplugin-kwlx7                                            3/3     Running     0          6m25s
csi-cephfsplugin-m4vv7                                            3/3     Running     0          6m25s
csi-cephfsplugin-provisioner-576f6bb67f-kf77f                     6/6     Running     0          6m25s
csi-cephfsplugin-provisioner-576f6bb67f-mmljw                     6/6     Running     0          6m25s
csi-cephfsplugin-qdcpf                                            3/3     Running     0          6m25s
csi-rbdplugin-5pc4z                                               3/3     Running     0          6m25s
csi-rbdplugin-8b79m                                               3/3     Running     0          6m25s
csi-rbdplugin-8cpbv                                               3/3     Running     0          6m25s
csi-rbdplugin-n5wlh                                               3/3     Running     0          6m25s
csi-rbdplugin-provisioner-69b9b89d86-5kz5s                        6/6     Running     0          6m25s
csi-rbdplugin-provisioner-69b9b89d86-7z59p                        6/6     Running     0          6m25s
csi-rbdplugin-q4rrs                                               3/3     Running     0          6m25s
csi-rbdplugin-q6lvf                                               3/3     Running     0          6m25s
noobaa-core-0                                                     1/1     Running     0          4m52s
noobaa-db-pg-0                                                    1/1     Running     0          4m52s
noobaa-endpoint-6cb8ddf94-8pbbx                                   1/1     Running     0          3m6s
noobaa-operator-7d59fb884d-zkt6t                                  1/1     Running     0          73m
ocs-metrics-exporter-855cfcbc99-hrqxn                             1/1     Running     0          73m
ocs-operator-64c646957-p94bh                                      1/1     Running     0          73m
rook-ceph-crashcollector-ip-10-0-130-232-65d74874d6-7j4bq         1/1     Running     0          4m28s
rook-ceph-crashcollector-ip-10-0-190-243-59674ff8-klfqk           1/1     Running     0          4m54s
rook-ceph-crashcollector-ip-10-0-206-139-7559b4997b-k5tl6         1/1     Running     0          4m53s
rook-ceph-mds-ocs-storagecluster-cephfilesystem-a-7b59cc9b8wg8h   2/2     Running     0          4m28s
rook-ceph-mds-ocs-storagecluster-cephfilesystem-b-cc76c6b8x8vc9   2/2     Running     0          4m27s
rook-ceph-mgr-a-c7d597fb8-j9z9z                                   2/2     Running     0          5m14s
rook-ceph-mon-a-6cd49d6988-pkt78                                  2/2     Running     0          6m16s
rook-ceph-mon-b-cf866b69c-p2xg4                                   2/2     Running     0          5m43s
rook-ceph-mon-c-68cffcc7cb-x7mbr                                  2/2     Running     0          5m30s
rook-ceph-operator-5975ddcfb6-cdp8r                               1/1     Running     0          73m
rook-ceph-osd-0-745f49d599-x79d2                                  2/2     Running     0          4m54s
rook-ceph-osd-1-7885c8974-7qhjq                                   2/2     Running     0          4m53s
rook-ceph-osd-2-8496b54994-cglx8                                  2/2     Running     0          4m53s
rook-ceph-osd-prepare-ocs-deviceset-0-data-0tvpk7-q9hbk           0/1     Completed   0          5m8s
rook-ceph-osd-prepare-ocs-deviceset-1-data-0gpxjw-fb7sl           0/1     Completed   0          5m8s
rook-ceph-osd-prepare-ocs-deviceset-2-data-0cctjb-rbq7c           0/1     Completed   0          5m7s
$ 
```

We can also check that the `StorageCluster` and `Cephcluster` are Ready/Healthy

```bash
$ oc get storagecluster
NAME                 AGE   PHASE   EXTERNAL   CREATED AT             VERSION
ocs-storagecluster   37m   Ready              2021-12-08T09:02:16Z   4.8.0
$ 
$ oc get cephcluster
NAME                             DATADIRHOSTPATH   MONCOUNT   AGE   PHASE   MESSAGE                        HEALTH      EXTERNAL
ocs-storageclust
```

#### validate components running on correct nodes

For simplicity we create a variable which will server as a filter in `egrep` for master nodes:

```bash
$ CP_NODES=`oc get nodes -l node-role.kubernetes.io/master= |awk '/master/ {print $1}'|tr '\n' '|' |sed 's/|$//g'`
$
$ echo $CP_NODES
ip-10-0-130-232.us-west-2.compute.internal|ip-10-0-190-243.us-west-2.compute.internal|ip-10-0-206-139.us-west-2.compute.internal
$ 
```

First, let's see which components are **not** running on the control plain nodes :

```bash
$ oc get po -o wide |egrep -v $CP_NODES
NAME                                                              READY   STATUS      RESTARTS   AGE    IP             NODE                                         NOMINATED NODE   READINESS GATES
csi-cephfsplugin-cg2cp                                            3/3     Running     0          38m    10.0.218.52    ip-10-0-218-52.us-west-2.compute.internal    <none>           <none>
csi-cephfsplugin-kwlx7                                            3/3     Running     0          38m    10.0.145.247   ip-10-0-145-247.us-west-2.compute.internal   <none>           <none>
csi-cephfsplugin-qdcpf                                            3/3     Running     0          38m    10.0.173.232   ip-10-0-173-232.us-west-2.compute.internal   <none>           <none>
csi-rbdplugin-8b79m                                               3/3     Running     0          38m    10.0.218.52    ip-10-0-218-52.us-west-2.compute.internal    <none>           <none>
csi-rbdplugin-8cpbv                                               3/3     Running     0          38m    10.0.145.247   ip-10-0-145-247.us-west-2.compute.internal   <none>           <none>
csi-rbdplugin-q6lvf                                               3/3     Running     0          38m    10.0.173.232   ip-10-0-173-232.us-west-2.compute.internal   <none>           <none>
$ 
```

This is expected and desired as those pods are needed to fulfill mount requests for pods.

Cross check which components are running on control plane nodes:

```bash
$ oc get po -o wide |egrep  $CP_NODES
csi-cephfsplugin-bq5cg                                            3/3     Running     0          38m    10.0.130.232   ip-10-0-130-232.us-west-2.compute.internal   <none>           <none>
csi-cephfsplugin-cwbhw                                            3/3     Running     0          38m    10.0.190.243   ip-10-0-190-243.us-west-2.compute.internal   <none>           <none>
csi-cephfsplugin-m4vv7                                            3/3     Running     0          38m    10.0.206.139   ip-10-0-206-139.us-west-2.compute.internal   <none>           <none>
csi-cephfsplugin-provisioner-576f6bb67f-kf77f                     6/6     Running     0          38m    10.130.0.41    ip-10-0-130-232.us-west-2.compute.internal   <none>           <none>
csi-cephfsplugin-provisioner-576f6bb67f-mmljw                     6/6     Running     0          38m    10.129.0.49    ip-10-0-190-243.us-west-2.compute.internal   <none>           <none>
csi-rbdplugin-5pc4z                                               3/3     Running     0          38m    10.0.190.243   ip-10-0-190-243.us-west-2.compute.internal   <none>           <none>
csi-rbdplugin-n5wlh                                               3/3     Running     0          38m    10.0.130.232   ip-10-0-130-232.us-west-2.compute.internal   <none>           <none>
csi-rbdplugin-provisioner-69b9b89d86-5kz5s                        6/6     Running     0          38m    10.128.0.73    ip-10-0-206-139.us-west-2.compute.internal   <none>           <none>
csi-rbdplugin-provisioner-69b9b89d86-7z59p                        6/6     Running     0          38m    10.129.0.48    ip-10-0-190-243.us-west-2.compute.internal   <none>           <none>
csi-rbdplugin-q4rrs                                               3/3     Running     0          38m    10.0.206.139   ip-10-0-206-139.us-west-2.compute.internal   <none>           <none>
noobaa-core-0                                                     1/1     Running     0          36m    10.128.0.80    ip-10-0-206-139.us-west-2.compute.internal   <none>           <none>
noobaa-db-pg-0                                                    1/1     Running     0          36m    10.129.0.56    ip-10-0-190-243.us-west-2.compute.internal   <none>           <none>
noobaa-endpoint-6cb8ddf94-8pbbx                                   1/1     Running     0          34m    10.129.0.58    ip-10-0-190-243.us-west-2.compute.internal   <none>           <none>
noobaa-operator-7d59fb884d-zkt6t                                  1/1     Running     0          105m   10.128.0.72    ip-10-0-206-139.us-west-2.compute.internal   <none>           <none>
ocs-metrics-exporter-855cfcbc99-hrqxn                             1/1     Running     0          105m   10.129.0.46    ip-10-0-190-243.us-west-2.compute.internal   <none>           <none>
ocs-operator-64c646957-p94bh                                      1/1     Running     0          105m   10.130.0.40    ip-10-0-130-232.us-west-2.compute.internal   <none>           <none>
rook-ceph-crashcollector-ip-10-0-130-232-65d74874d6-7j4bq         1/1     Running     0          36m    10.130.0.50    ip-10-0-130-232.us-west-2.compute.internal   <none>           <none>
rook-ceph-crashcollector-ip-10-0-190-243-59674ff8-klfqk           1/1     Running     0          36m    10.129.0.55    ip-10-0-190-243.us-west-2.compute.internal   <none>           <none>
rook-ceph-crashcollector-ip-10-0-206-139-7559b4997b-k5tl6         1/1     Running     0          36m    10.128.0.79    ip-10-0-206-139.us-west-2.compute.internal   <none>           <none>
rook-ceph-mds-ocs-storagecluster-cephfilesystem-a-7b59cc9b8wg8h   2/2     Running     0          36m    10.130.0.49    ip-10-0-130-232.us-west-2.compute.internal   <none>           <none>
rook-ceph-mds-ocs-storagecluster-cephfilesystem-b-cc76c6b8x8vc9   2/2     Running     0          36m    10.130.0.51    ip-10-0-130-232.us-west-2.compute.internal   <none>           <none>
rook-ceph-mgr-a-c7d597fb8-j9z9z                                   2/2     Running     0          36m    10.130.0.44    ip-10-0-130-232.us-west-2.compute.internal   <none>           <none>
rook-ceph-mon-a-6cd49d6988-pkt78                                  2/2     Running     0          38m    10.129.0.51    ip-10-0-190-243.us-west-2.compute.internal   <none>           <none>
rook-ceph-mon-b-cf866b69c-p2xg4                                   2/2     Running     0          37m    10.128.0.75    ip-10-0-206-139.us-west-2.compute.internal   <none>           <none>
rook-ceph-mon-c-68cffcc7cb-x7mbr                                  2/2     Running     0          37m    10.130.0.43    ip-10-0-130-232.us-west-2.compute.internal   <none>           <none>
rook-ceph-operator-5975ddcfb6-cdp8r                               1/1     Running     0          105m   10.129.0.45    ip-10-0-190-243.us-west-2.compute.internal   <none>           <none>
rook-ceph-osd-0-745f49d599-x79d2                                  2/2     Running     0          36m    10.129.0.54    ip-10-0-190-243.us-west-2.compute.internal   <none>           <none>
rook-ceph-osd-1-7885c8974-7qhjq                                   2/2     Running     0          36m    10.130.0.47    ip-10-0-130-232.us-west-2.compute.internal   <none>           <none>
rook-ceph-osd-2-8496b54994-cglx8                                  2/2     Running     0          36m    10.128.0.78    ip-10-0-206-139.us-west-2.compute.internal   <none>           <none>
rook-ceph-osd-prepare-ocs-deviceset-0-data-0tvpk7-q9hbk           0/1     Completed   0          36m    10.130.0.46    ip-10-0-130-232.us-west-2.compute.internal   <none>           <none>
rook-ceph-osd-prepare-ocs-deviceset-1-data-0gpxjw-fb7sl           0/1     Completed   0          36m    10.128.0.77    ip-10-0-206-139.us-west-2.compute.internal   <none>           <none>
rook-ceph-osd-prepare-ocs-deviceset-2-data-0cctjb-rbq7c           0/1     Completed   0          36m    10.129.0.52    ip-10-0-190-243.us-west-2.compute.internal   <none>           <none>
$ 
```



###  Validation 
For validation I do use my scriptset GitHub - dmoessne/ocs4-tests I use for normal setups as well (S3 still missing..) which creates some pods requesting ocs block and file storage

$ git clone https://github.com/dmoessne/ocs4-tests.git
$ cd ocs4-tests
$ $ ./liftoff.sh 
creating project for nginx block test
Now using project "nginx-block" on server "https://api.dmoessne.emeatam.support:6443".

You can add applications to this project with the 'new-app' command. For example, try:

[...]
service/ngx-fs-gp1kpmvqq14ybkmw5dsh-pod created
route.route.openshift.io/ngx-fs-gp1kpmvqq14ybkmw5dsh-pod created
$ oc 

Validate storage has been created:

$ oc get pv |grep ngin
pvc-085912ab-e4ea-4f19-befb-70b86f52179f   1Mi        RWO            Delete           Bound    nginx-file/ngx-fs-7x8hou1cd1-pod                ocs-storagecluster-cephfs              93s
pvc-12c0110a-594f-481b-9dc2-d1bc064baf23   1Mi        RWO            Delete           Bound    nginx-block/ngx-bk-bbarkbju5n-pod               ocs-storagecluster-ceph-rbd            3m45s
pvc-2db0a914-ea4e-4c9b-bfaa-951963366c22   1Mi        RWO            Delete           Bound    nginx-block/ngx-bk-y0vdq0ygd5-pod               ocs-storagecluster-ceph-rbd            3m58s
pvc-51758d68-2911-499f-bfe8-38b28a6083fa   1Mi        RWO            Delete           Bound    nginx-block/ngx-bk-jjo6fa4uuk-pod               ocs-storagecluster-ceph-rbd            3m56s
pvc-63ef1a1b-602b-464e-ade2-9ec4a5f6a626   1Mi        RWO            Delete           Bound    nginx-file/ngx-fs-lpow7jm8ol-pod                ocs-storagecluster-cephfs              87s
pvc-684c810e-86cf-4e02-8184-8d04d7727aa0   1Mi        RWO            Delete           Bound    nginx-file/ngx-fs-ec4ipr3l50-pod                ocs-storagecluster-cephfs              95s
pvc-8abbd56f-db52-4a48-a138-adb3e7e6341d   1Mi        RWO            Delete           Bound    nginx-block/ngx-bk-yxurnvyjfu-pod               ocs-storagecluster-ceph-rbd            3m54s
pvc-8c31e985-360f-42e8-b925-869dd76420fd   1Mi        RWO            Delete           Bound    nginx-block/ngx-bk-k7afqdpb7r-pod               ocs-storagecluster-ceph-rbd            4m
pvc-a707c5ab-2b83-4750-8358-fa5807f538c1   1Mi        RWO            Delete           Bound    nginx-block/ngx-bk-tubvhwjg1w-pod               ocs-storagecluster-ceph-rbd            3m51s
pvc-bab0581b-259d-4ab2-93ac-ec8015e4d514   1Mi        RWO            Delete           Bound    nginx-block/ngx-bk-lrqukxyvvx-pod               ocs-storagecluster-ceph-rbd            4m1s
pvc-bbcb1e00-d360-47bb-a07f-8b3b58734088   1Mi        RWO            Delete           Bound    nginx-file/ngx-fs-ey52op8km1-pod                ocs-storagecluster-cephfs              84s
pvc-be10ec39-95a3-42d6-91e0-7ed7019bff3b   1Mi        RWO            Delete           Bound    nginx-file/ngx-fs-km0b0m0hf4-pod                ocs-storagecluster-cephfs              101s
pvc-c8607d6d-4c2e-45d6-b0d4-d7afea8444b1   1Mi        RWO            Delete           Bound    nginx-file/ngx-fs-77bv0umt6g-pod                ocs-storagecluster-cephfs              89s
pvc-c9ab46f9-64c3-476d-a791-88fde9dd0aa5   1Mi        RWO            Delete           Bound    nginx-file/ngx-fs-o88id1mk5c-pod                ocs-storagecluster-cephfs              99s
pvc-ca7579ee-06fb-4b91-9548-8a30fc258e24   1Mi        RWO            Delete           Bound    nginx-file/ngx-fs-fs2mgqdr3s-pod                ocs-storagecluster-cephfs              91s
pvc-cc11b4ed-4dde-4796-abff-63bd08d8d645   1Mi        RWO            Delete           Bound    nginx-file/ngx-fs-vdk57hl85k-pod                ocs-storagecluster-cephfs              86s
pvc-dc23828d-4ed9-4bf3-83e8-7fbb3e5d9c27   1Mi        RWO            Delete           Bound    nginx-file/ngx-fs-hojks8xy6l-pod                ocs-storagecluster-cephfs              97s
pvc-e6292e6f-e6ca-4b1f-b860-2120ee5654ea   1Mi        RWO            Delete           Bound    nginx-block/ngx-bk-c7ymm6dkt2-pod               ocs-storagecluster-ceph-rbd            3m52s
pvc-f0d2eb49-5183-427d-9dcb-b7d3f989bb25   1Mi        RWO            Delete           Bound    nginx-block/ngx-bk-hp3gvq3io3-pod               ocs-storagecluster-ceph-rbd            3m49s
pvc-f88e847a-a2de-4b71-91ed-71810454d0a6   1Mi        RWO            Delete           Bound    nginx-block/ngx-bk-66e6stvf7l-pod               ocs-storagecluster-ceph-rbd            3m47s
$$ oc get po -A |grep ngin
nginx-block                                        ngx-bk-3yvq4pl37ld57d3806b6-pod-7hsfl                                 1/1     Running     0          4m6s
nginx-block                                        ngx-bk-4vqyx6ayibpkcotmu6rj-pod-qchn9                                 1/1     Running     0          4m15s
nginx-block                                        ngx-bk-6276v54qs1bwc3hf8jdm-pod-69csd                                 1/1     Running     0          4m19s
nginx-block                                        ngx-bk-6t3edirjl1vd2pkv2p1a-pod-49f7d                                 1/1     Running     0          4m8s
nginx-block                                        ngx-bk-cp21ug8wx18m1dwf11j0-pod-hcbjl                                 1/1     Running     0          4m22s
nginx-block                                        ngx-bk-kjq57fjialuhdajxy4ml-pod-dhh7l                                 1/1     Running     0          4m17s
nginx-block                                        ngx-bk-ms301ivb5fjp4o31a37n-pod-q7fnq                                 1/1     Running     0          4m10s
nginx-block                                        ngx-bk-npiej3qk4feh5xqn7lhm-pod-ql7ls                                 1/1     Running     0          4m20s
nginx-block                                        ngx-bk-v1trl8aqewgy0k0ixu7u-pod-k8rsn                                 1/1     Running     0          4m11s
nginx-block                                        ngx-bk-yvojtli8ju17nvwskob0-pod-vj5wn                                 1/1     Running     0          4m13s
nginx-file                                         ngx-fs-5iovobxyirjs81s7qakn-pod-v8rlf                                 1/1     Running     0          106s
nginx-file                                         ngx-fs-5kjxbm1sqg858bdmqv7f-pod-7xfxl                                 1/1     Running     0          118s
nginx-file                                         ngx-fs-gp1kpmvqq14ybkmw5dsh-pod-vbj4s                                 1/1     Running     0          105s
nginx-file                                         ngx-fs-h6lawshdie6f12ppk841-pod-bwm2g                                 1/1     Running     0          2m2s
nginx-file                                         ngx-fs-hdeh8nc5h8u63ntcyhab-pod-q4j7p                                 1/1     Running     0          112s
nginx-file                                         ngx-fs-oqtj14fgbfi0fbiwh1b7-pod-vhn8w                                 1/1     Running     0          115s
nginx-file                                         ngx-fs-v1i1onaldfeo7yc2cnw7-pod-smlpc                                 1/1     Running     0          108s
nginx-file                                         ngx-fs-vl77adldvk4s5pve5dov-pod-gr76r                                 1/1     Running     0          110s
nginx-file                                         ngx-fs-vwkssf7dxklsj30lu2t2-pod-294nm                                 1/1     Running     0          2m
nginx-file                                         ngx-fs-xj5nfk0tu5lg52rwv4f1-pod-qvw7w                                 1/1     Running     0          114s
$
Pods are created as well as PVs .


###  Upgrade
To be sure upgrade is working as well, let's test one.

Current version is as follows:

$ oc adm upgrade
Cluster version is 4.8.14

Upgradeable=False

  Reason: AdminAckRequired
  Message: Kubernetes 1.22 and therefore OpenShift 4.9 remove several APIs which require admin consideration. Please see
the knowledge article https://access.redhat.com/articles/6329921 for details and instructions.


Updates:

VERSION IMAGE
4.8.15  quay.io/openshift-release-dev/ocp-release@sha256:92b684258b9f80dadce5b2f4efce0e110fb92b9f08f8837bdcbe7393c57d388f
4.8.17  quay.io/openshift-release-dev/ocp-release@sha256:1935b6c8277e351550bd7bfcc4d5df7c4ba0f7a90165c022e2ffbe789b15574a
4.8.18  quay.io/openshift-release-dev/ocp-release@sha256:321aae3d3748c589bc2011062cee9fd14e106f258807dc2d84ced3f7461160ea
4.8.19  quay.io/openshift-release-dev/ocp-release@sha256:ac19c975be8b8a449dedcdd7520e970b1cc827e24042b8976bc0495da32c6b59
4.8.20  quay.io/openshift-release-dev/ocp-release@sha256:ca7a910891da55bb3b555fab1973878c3918dbf908cfd415ef2941287300e698
4.8.21  quay.io/openshift-release-dev/ocp-release@sha256:f7e664bf56c882f934ed02eb05018e2683ddf42135e33eae1e4192948372d5ae
4.8.22  quay.io/openshift-release-dev/ocp-release@sha256:019e313e9d073c21aeae5c36b6b7e010783ad284c6bc0b0f716bbac501e20d68
$ 
$ oc get co 
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
authentication                             4.8.14    True        False         False      6h34m
baremetal                                  4.8.14    True        False         False      7h
cloud-credential                           4.8.14    True        False         False      7h7m
cluster-autoscaler                         4.8.14    True        False         False      7h1m
config-operator                            4.8.14    True        False         False      7h2m
console                                    4.8.14    True        False         False      6h49m
csi-snapshot-controller                    4.8.14    True        False         False      7h2m
dns                                        4.8.14    True        False         False      7h
etcd                                       4.8.14    True        False         False      7h1m
image-registry                             4.8.14    True        False         False      6h54m
ingress                                    4.8.14    True        False         False      6h53m
insights                                   4.8.14    True        False         False      6h55m
kube-apiserver                             4.8.14    True        False         False      6h58m
kube-controller-manager                    4.8.14    True        False         False      7h
kube-scheduler                             4.8.14    True        False         False      6h59m
kube-storage-version-migrator              4.8.14    True        False         False      7h2m
machine-api                                4.8.14    True        False         False      6h57m
machine-approver                           4.8.14    True        False         False      7h1m
machine-config                             4.8.14    True        False         False      7h
marketplace                                4.8.14    True        False         False      7h1m
monitoring                                 4.8.14    True        False         False      6h52m
network                                    4.8.14    True        False         False      7h2m
node-tuning                                4.8.14    True        False         False      7h1m
openshift-apiserver                        4.8.14    True        False         False      6h57m
openshift-controller-manager               4.8.14    True        False         False      7h
openshift-samples                          4.8.14    True        False         False      6h58m
operator-lifecycle-manager                 4.8.14    True        False         False      7h1m
operator-lifecycle-manager-catalog         4.8.14    True        False         False      7h1m
operator-lifecycle-manager-packageserver   4.8.14    True        False         False      6h57m
service-ca                                 4.8.14    True        False         False      7h2m
storage                                    4.8.14    True        False         False      7h1m
$ 


Start the update 

$ oc adm upgrade --to-latest
Updating to latest version 4.8.22
$ 

After the update is done, let's check again:

$ oc adm upgrade
Cluster version is 4.8.22

Upgradeable=False

  Reason: AdminAckRequired
  Message: Kubernetes 1.22 and therefore OpenShift 4.9 remove several APIs which require admin consideration. Please see the knowledge article https://access.redhat.com/articles/6329921 for details and instructions.


No updates available. You may force an upgrade to a specific release image, but doing so may not be supported and result in downtime or data loss.
$ 
$ oc get co
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
authentication                             4.8.22    True        False         False      8h
baremetal                                  4.8.22    True        False         False      8h
cloud-credential                           4.8.22    True        False         False      8h
cluster-autoscaler                         4.8.22    True        False         False      8h
config-operator                            4.8.22    True        False         False      8h
console                                    4.8.22    True        False         False      8h
csi-snapshot-controller                    4.8.22    True        False         False      8h
dns                                        4.8.22    True        False         False      8h
etcd                                       4.8.22    True        False         False      8h
image-registry                             4.8.22    True        False         False      8h
ingress                                    4.8.22    True        False         False      8h
insights                                   4.8.22    True        False         False      8h
kube-apiserver                             4.8.22    True        False         False      8h
kube-controller-manager                    4.8.22    True        False         False      8h
kube-scheduler                             4.8.22    True        False         False      8h
kube-storage-version-migrator              4.8.22    True        False         False      21m
machine-api                                4.8.22    True        False         False      8h
machine-approver                           4.8.22    True        False         False      8h
machine-config                             4.8.22    True        False         False      14m
marketplace                                4.8.22    True        False         False      8h
monitoring                                 4.8.22    True        False         False      8h
network                                    4.8.22    True        False         False      8h
node-tuning                                4.8.22    True        False         False      14m
openshift-apiserver                        4.8.22    True        False         False      8h
openshift-controller-manager               4.8.22    True        False         False      58m
openshift-samples                          4.8.22    True        False         False      60m
operator-lifecycle-manager                 4.8.22    True        False         False      8h
operator-lifecycle-manager-catalog         4.8.22    True        False         False      8h
operator-lifecycle-manager-packageserver   4.8.22    True        False         False      8h
service-ca                                 4.8.22    True        False         False      8h
storage                                    4.8.22    True        False         False      20m
$ 
$ oc get mcp 
NAME     CONFIG                                             UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
master   rendered-master-fd671ada4df5b79b19a19599adc5f34f   True      False      False      3              3                   3                     0                      8h
worker   rendered-worker-133b58797688b0749602c29c7aea1066   True      False      False      3              3                   3                     0                      8h
$ 
$ oc get nodes -o wide
NAME                                         STATUS   ROLES    AGE   VERSION           INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                                                       KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-0-130-232.us-west-2.compute.internal   Ready    master   8h    v1.21.6+81bc627   10.0.130.232   <none>        Red Hat Enterprise Linux CoreOS 48.84.202111222303-0 (Ootpa)   4.18.0-305.28.1.el8_4.x86_64   cri-o://1.21.4-3.rhaos4.8.git84fa55d.el8
ip-10-0-145-247.us-west-2.compute.internal   Ready    worker   8h    v1.21.6+81bc627   10.0.145.247   <none>        Red Hat Enterprise Linux CoreOS 48.84.202111222303-0 (Ootpa)   4.18.0-305.28.1.el8_4.x86_64   cri-o://1.21.4-3.rhaos4.8.git84fa55d.el8
ip-10-0-173-232.us-west-2.compute.internal   Ready    worker   8h    v1.21.6+81bc627   10.0.173.232   <none>        Red Hat Enterprise Linux CoreOS 48.84.202111222303-0 (Ootpa)   4.18.0-305.28.1.el8_4.x86_64   cri-o://1.21.4-3.rhaos4.8.git84fa55d.el8
ip-10-0-190-243.us-west-2.compute.internal   Ready    master   8h    v1.21.6+81bc627   10.0.190.243   <none>        Red Hat Enterprise Linux CoreOS 48.84.202111222303-0 (Ootpa)   4.18.0-305.28.1.el8_4.x86_64   cri-o://1.21.4-3.rhaos4.8.git84fa55d.el8
ip-10-0-206-139.us-west-2.compute.internal   Ready    master   8h    v1.21.6+81bc627   10.0.206.139   <none>        Red Hat Enterprise Linux CoreOS 48.84.202111222303-0 (Ootpa)   4.18.0-305.28.1.el8_4.x86_64   cri-o://1.21.4-3.rhaos4.8.git84fa55d.el8
ip-10-0-218-52.us-west-2.compute.internal    Ready    worker   8h    v1.21.6+81bc627   10.0.218.52    <none>        Red Hat Enterprise Linux CoreOS 48.84.202111222303-0 (Ootpa)   4.18.0-305.28.1.el8_4.x86_64   cri-o://1.21.4-3.rhaos4.8.git84fa55d.el8
$ 

