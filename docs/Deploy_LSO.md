# Deploy LSO

References:
* [Install Red Hat OpenShift Container Storage 4.X in internal-attached mode using command line interface. - Red Hat Customer Portal](https://access.redhat.com/articles/5692201#overview-1)
* [Chapter 2. Deploy OpenShift Container Storage using local storage devices](https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.8/html/deploying_openshift_container_storage_using_bare_metal_infrastructure/deploy-using-local-storage-devices-bm)


We deploy using LSO (and later on ODF) based on [Install Red Hat OpenShift Container Storage 4.X in internal-attached mode using command line interface. - Red Hat Customer Portal](https://access.redhat.com/articles/5692201#overview-1). Files can be found in folder ```ocs```

**Mind**:

* if you want to use the files provided, make sure they fit to your setup, esp disk paths in ```04-05-LocalVolume-local-block.yaml``` and diak size later on for deployin ODF
  
* As I did not get autodiscovery for LSO running with multipath iscsi, we use the (older and more) manual mathod which still perfectly works. (section [Manual Method to create Persistent Volumes](https://access.redhat.com/articles/5692201#manual-method-to-create-persistent-volumes-5)

* Currently, LSO doesn't support multipath devices discovery (i.e autodiscovery & local volumeset) aren't going to work (Check [BZ 2089387] (https://bugzilla.redhat.com/show_bug.cgi?id=2089387) , we use the manual mathod which still perfectly works. (section [Manual Method to create Persistent Volumes](https://access.redhat.com/articles/5692201#manual-method-to-create-persistent-volumes-5)  

## Relevant folder content

```bash
<laptop-2>$ ls -l ocs/
total 44
-rw-rw-r--. 1 dm dm   81 Nov 21 11:39 01-Namespace-openshift-local-storage.yaml
-rw-rw-r--. 1 dm dm  182 Nov 21 11:39 02-OperatorGroup-local-operator-group.yaml
-rw-rw-r--. 1 dm dm  438 Nov 21 11:39 03-Subscription-local-storage-operator.yaml
-rw-rw-r--. 1 dm dm  444 Nov 21 14:47 04-05-LocalVolume-local-block.yaml
[...]
<laptop-2>$ 
```

### Create namespace, Operatorgroup (og) and Subscription (subs)

```bash
<laptop-2>$ cat ocs/01-Namespace-openshift-local-storage.yaml 
apiVersion: v1
kind: Namespace
metadata:
 name: openshift-local-storage
spec: {}
<laptop-2>$ 
<laptop-2>$ oc create -f ocs/01-Namespace-openshift-local-storage.yaml
namespace/openshift-local-storage created
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ oc get project openshift-local-storage
NAME                      DISPLAY NAME   STATUS
openshift-local-storage                  Active
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ cat ocs/02-OperatorGroup-local-operator-group.yaml 
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
 name: local-operator-group
 namespace: openshift-local-storage
spec:
 targetNamespaces:
 - openshift-local-storage
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ oc create -f ocs/02-OperatorGroup-local-operator-group.yaml 
operatorgroup.operators.coreos.com/local-operator-group created
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ cat ocs/03-Subscription-local-storage-operator.yaml 
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
 name: local-storage-operator
 namespace: openshift-local-storage
spec:
 channel: "4.8"  # <-- Channel should be used corresponding to the OCP version being used.
 installPlanApproval: Automatic
 name: local-storage-operator
 source: redhat-operators  # <-- Modify the name of the redhat-operators catalogsource if not default
 sourceNamespace: openshift-marketplace
<laptop-2>$ 
<laptop-2>$ oc create -f ocs/03-Subscription-local-storage-operator.yaml 
subscription.operators.coreos.com/local-storage-operator created
<laptop-2>$ 
```

### Modify and deploy LocalVolume

As stated above, getting autodiscovery of LSO working with multipathing did not work for me, so we create ```LocalVolume``` directly referring to ```/dev/mapper/mpatha```

```bash
<laptop-2>$ vim ocs/04-05-LocalVolume-local-block.yaml 
<laptop-2>$ cat ocs/04-05-LocalVolume-local-block.yaml
apiVersion: local.storage.openshift.io/v1
kind: LocalVolume
metadata:
  name: local-block
  namespace: openshift-local-storage
spec:
  nodeSelector:
    nodeSelectorTerms:
    - matchExpressions:
        - key: cluster.ocs.openshift.io/openshift-storage
          operator: In
          values:
          - ""
  storageClassDevices:
    - storageClassName: localblock
      volumeMode: Block
      devicePaths:
        - /dev/mapper/mpatha
        - /dev/mapper/mpatha
        - /dev/mapper/mpatha
<laptop-2>$ 
<laptop-2>$ oc create -f ocs/04-05-LocalVolume-local-block.yaml 
localvolume.local.storage.openshift.io/local-block created
<laptop-2>$ 
```

## Check if pods are running and PVs created

```bash
<laptop-2>$ oc get po -n openshift-local-storage 
NAME                                      READY   STATUS    RESTARTS   AGE
diskmaker-manager-fbcsd                   1/1     Running   0          40s
diskmaker-manager-gv76p                   1/1     Running   0          40s
diskmaker-manager-trp6m                   1/1     Running   0          40s
local-storage-operator-6d85677d55-nl5fl   1/1     Running   0          2m2s
<laptop-2>$ 
<laptop-2>$ oc get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
local-pv-1273d4c5   1Ti        RWO            Delete           Available           localblock              36s
local-pv-877bff48   1Ti        RWO            Delete           Available           localblock              31s
local-pv-ab07ba9    1Ti        RWO            Delete           Available           localblock              34s
<laptop-2>$ 
```

At this point we have 3 PVs created which we can then use to [deploy ODF on top of it](Deploy_ODF.md)
