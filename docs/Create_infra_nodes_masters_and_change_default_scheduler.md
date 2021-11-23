# Create infra nodes (masters) and change default scheduler

References:
* [Infrastructure Nodes in OpenShift 4](https://access.redhat.com/solutions/5034771)


As outlined in the top level document, the infra role label can be attached to any schedulable worker node. In case these infra labeled nodes are not masters, it is also possible to taint the infra nodes and repel not infra related workload, but allow infra workload by adding a toleration to these components.

As we have schedulable masters where we cannot add a taint easily without impacting master components but also want to keep user workload away from infra nodes (masters in this case) we need to apply an additional label to worker nodes and change the scheduler accordingly so it prepers these nodes for scheduling custom workload.

General information about infra node can be found at [Creating infrastructure machine sets | Machine management | OpenShift Container Platform 4.8](https://docs.openshift.com/container-platform/4.8/machine_management/creating-infrastructure-machinesets.html)

and especially at [Infrastructure Nodes in OpenShift 4](https://access.redhat.com/solutions/5034771) which is explaining also taints and machineconfig pools in more details.

**MIND** [Self-managed Red Hat OpenShift sizing and subscription guide](https://www.redhat.com/en/resources/self-managed-open-shift-sizing-sub-guide) which is discussing in section ```Infrastructure nodes``` which workload is entitled to run on infrastructure nodes

## Label master nodes as infra nodes

```bash
<laptop-2>$ oc label -l node-role.kubernetes.io/master nodes node-role.kubernetes.io/infra=""
node/ip-10-0-157-223.us-west-2.compute.internal labeled
node/ip-10-0-173-122.us-west-2.compute.internal labeled
node/ip-10-0-206-223.us-west-2.compute.internal labeled
<laptop-2>$ 
<laptop-2>$ oc get nodes
NAME                                         STATUS   ROLES                 AGE   VERSION
ip-10-0-148-134.us-west-2.compute.internal   Ready    worker                20h   v1.21.1+6438632
ip-10-0-157-223.us-west-2.compute.internal   Ready    infra,master,worker   20h   v1.21.1+6438632
ip-10-0-173-122.us-west-2.compute.internal   Ready    infra,master,worker   20h   v1.21.1+6438632
ip-10-0-177-190.us-west-2.compute.internal   Ready    worker                20h   v1.21.1+6438632
ip-10-0-206-223.us-west-2.compute.internal   Ready    infra,master,worker   20h   v1.21.1+6438632
<laptop-2>$ 
```

## Apply additional label to worker nodes

As outlined, we will apply an additional label ```node-role.kubernetes.io/app=""``` to worker nodes and change the scheduler to have this as default node selector:

```bash
<laptop-2>$ oc label -l node-role.kubernetes.io/master!= nodes node-role.kubernetes.io/app=""
node/ip-10-0-148-134.us-west-2.compute.internal labeled
node/ip-10-0-177-190.us-west-2.compute.internal labeled
<laptop-2>$ 
<laptop-2>$ oc patch scheduler cluster --type=merge -p '{"spec":{"defaultNodeSelector":"node-role.kubernetes.io/app="}}'
scheduler.config.openshift.io/cluster patched
<laptop-2>$ 
```

Now we can move on to move entitled workload on the infra nodes, staring with [routers](Scale_and_move_routers_to_infra.md)
