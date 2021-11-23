# Make masters schedulable and label for ODF

References:
* [Infrastructure Nodes in OpenShift 4](https://access.redhat.com/solutions/5034771)


Before deploying LSO on the cluster, we make the masters schedulable, so we can easily get workload on it. we will label the master nodes with ```cluster.ocs.openshift.io/openshift-storage=""``` as we will use that label for binding LSO to it.

Files used fopr deploying are available in this git repo for use, however you may want or have to change them as needed.

If you have mapped the iscsi LUNs to different nodes, mind to label the right nodes.

In addition to official OCP and ODF documentation, also [Install Red Hat OpenShift Container Storage 4.X in internal-attached mode using command line interface. - Red Hat Customer Portal](https://access.redhat.com/articles/5692201#overview-1) has been used

## Make masters schedulable

```bash
<laptop-2>$ oc patch schedulers.config.openshift.io/cluster --type merge --patch '{"spec":{"mastersSchedulable": true}}'
scheduler.config.openshift.io/cluster patched
<laptop-2>$ 
```

## validate

```bash
<laptop-2>$ oc get nodes 
NAME                                         STATUS   ROLES           AGE     VERSION
ip-10-0-148-134.us-west-2.compute.internal   Ready    worker          3h57m   v1.21.1+6438632
ip-10-0-157-223.us-west-2.compute.internal   Ready    master,worker   4h4m    v1.21.1+6438632
ip-10-0-173-122.us-west-2.compute.internal   Ready    master,worker   4h4m    v1.21.1+6438632
ip-10-0-177-190.us-west-2.compute.internal   Ready    worker          3h58m   v1.21.1+6438632
ip-10-0-206-223.us-west-2.compute.internal   Ready    master,worker   4h4m    v1.21.1+6438632
<laptop-2>$ 
<laptop-2>$ oc label -l node-role.kubernetes.io/master nodes cluster.ocs.openshift.io/openshift-storage=""
node/ip-10-0-157-223.us-west-2.compute.internal labeled
node/ip-10-0-173-122.us-west-2.compute.internal labeled
node/ip-10-0-206-223.us-west-2.compute.internal labeled
<laptop-2>$ 
```

Right away we can now [depoy Locsl Storage Operator(LSO)](Deploy_LSO.md)
