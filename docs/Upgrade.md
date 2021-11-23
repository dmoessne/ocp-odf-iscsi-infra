# Upgrade

To validate if everything is working as expected the cluster will be upgraded to the latest stable version:

## Status prior to upgrade

```bash
<laptop-2>$ oc get co 
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
authentication                             4.8.18    True        False         False      18h
baremetal                                  4.8.18    True        False         False      22h
cloud-credential                           4.8.18    True        False         False      22h
cluster-autoscaler                         4.8.18    True        False         False      22h
config-operator                            4.8.18    True        False         False      22h
console                                    4.8.18    True        False         False      21h
csi-snapshot-controller                    4.8.18    True        False         False      22h
dns                                        4.8.18    True        False         False      22h
etcd                                       4.8.18    True        False         False      22h
image-registry                             4.8.18    True        False         False      40m
ingress                                    4.8.18    True        False         False      22h
insights                                   4.8.18    True        False         False      22h
kube-apiserver                             4.8.18    True        False         False      22h
kube-controller-manager                    4.8.18    True        False         False      22h
kube-scheduler                             4.8.18    True        False         False      22h
kube-storage-version-migrator              4.8.18    True        False         False      18h
machine-api                                4.8.18    True        False         False      22h
machine-approver                           4.8.18    True        False         False      22h
machine-config                             4.8.18    True        False         False      18h
marketplace                                4.8.18    True        False         False      22h
monitoring                                 4.8.18    True        False         False      22h
network                                    4.8.18    True        False         False      22h
node-tuning                                4.8.18    True        False         False      22h
openshift-apiserver                        4.8.18    True        False         False      22h
openshift-controller-manager               4.8.18    True        False         False      22h
openshift-samples                          4.8.18    True        False         False      22h
operator-lifecycle-manager                 4.8.18    True        False         False      22h
operator-lifecycle-manager-catalog         4.8.18    True        False         False      22h
operator-lifecycle-manager-packageserver   4.8.18    True        False         False      22h
service-ca                                 4.8.18    True        False         False      22h
storage                                    4.8.18    True        False         False      18h
<laptop-2>$ 
```

## Trigger update

```bash
<laptop-2>$ oc adm upgrade
Cluster version is 4.8.18

Upgradeable=False

  Reason: AdminAckRequired
  Message: Kubernetes 1.22 and therefore OpenShift 4.9 remove several APIs which require admin consideration. Please see
the knowledge article https://access.redhat.com/articles/6329921 for details and instructions.


Updates:

VERSION IMAGE
4.8.19  quay.io/openshift-release-dev/ocp-release@sha256:ac19c975be8b8a449dedcdd7520e970b1cc827e24042b8976bc0495da32c6b59
<laptop-2>$ oc adm upgrade --to-latest
```

## Validate update

After waiting some time the cluster got updated

```bash
<laptop-2>$ oc adm upgrade --to-latest
<laptop-2>$ oc get co 
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
authentication                             4.8.19    True        False         False      3h53m
baremetal                                  4.8.19    True        False         False      31h
cloud-credential                           4.8.19    True        False         False      31h
cluster-autoscaler                         4.8.19    True        False         False      31h
config-operator                            4.8.19    True        False         False      31h
console                                    4.8.19    True        False         False      30h
csi-snapshot-controller                    4.8.19    True        False         False      31h
dns                                        4.8.19    True        False         False      31h
etcd                                       4.8.19    True        False         False      31h
image-registry                             4.8.19    True        False         False      9h
ingress                                    4.8.19    True        False         False      17m
insights                                   4.8.19    True        False         False      31h
kube-apiserver                             4.8.19    True        False         False      31h
kube-controller-manager                    4.8.19    True        False         False      31h
kube-scheduler                             4.8.19    True        False         False      31h
kube-storage-version-migrator              4.8.19    True        False         False      8h
machine-api                                4.8.19    True        False         False      31h
machine-approver                           4.8.19    True        False         False      31h
machine-config                             4.8.19    True        False         False      9m11s
marketplace                                4.8.19    True        False         False      31h
monitoring                                 4.8.19    True        False         False      30h
network                                    4.8.19    True        False         False      31h
node-tuning                                4.8.19    True        False         False      8h
openshift-apiserver                        4.8.19    True        False         False      31h
openshift-controller-manager               4.8.19    True        False         False      8h
openshift-samples                          4.8.19    True        False         False      8h
operator-lifecycle-manager                 4.8.19    True        False         False      31h
operator-lifecycle-manager-catalog         4.8.19    True        False         False      31h
operator-lifecycle-manager-packageserver   4.8.19    True        False         False      31h
service-ca                                 4.8.19    True        False         False      31h
storage                                    4.8.19    True        False         False      17m
<laptop-2>$ oc adm upgrade
Cluster version is 4.8.19

Upgradeable=False

  Reason: AdminAckRequired
  Message: Kubernetes 1.22 and therefore OpenShift 4.9 remove several APIs which require admin consideration. Please see
the knowledge article https://access.redhat.com/articles/6329921 for details and instructions.


No updates available. You may force an upgrade to a specific release image, but doing so may not be supported and result in downtime or data loss.
<laptop-2>$ 
<laptop-2>$ oc get mcp 
NAME     CONFIG                                             UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
master   rendered-master-ee776e4231934d51f865dc8d56476c49   True      False      False      3              3                   3                     0                      31h
worker   rendered-worker-ccc15726cbe45437cff027ee43c595be   True      False      False      2              2                   2                     0                      31h
<laptop-2>$ 
```

In case the upgrade got stuck, check a mcp is stuck and if ODF pods are pending in which case most likely the namespace allocation is missing ```oc annotate namespace openshift-storage openshift.io/node-selector=```. Killing pending pods should do the trick

This conclude this demo
