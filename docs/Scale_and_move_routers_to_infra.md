# Scale and move routers to infra

References:
* [Infrastructure Nodes in OpenShift 4](https://access.redhat.com/solutions/5034771)
* [Moving the router](https://docs.openshift.com/container-platform/4.8/machine_management/creating-infrastructure-machinesets.html#infrastructure-moving-router_creating-infrastructure-machinesets)

As we have 3 infra nodes here it seems reasonable to also scalte the routers to 3:

## Check where router pods are running

```bash
<laptop-2>$ oc get po -o wide -n openshift-ingress
NAME                              READY   STATUS    RESTARTS   AGE   IP            NODE                                         NOMINATED NODE   READINESS GATES
router-default-7cdd759b6b-fvpwn   1/1     Running   0          20h   10.131.0.13   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
router-default-7cdd759b6b-x69pv   1/1     Running   0          20h   10.128.2.7    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
<laptop-2>$ 
```

## patch ingresscontroller

```bash
<laptop-2>$ 
oc patch ingresscontroller/default -n  openshift-ingress-operator  --type=merge -p '{"spec":{"nodePlacement": {"nodeSelector": {"matchLabels": {"node-role.kubernetes.io/infra": ""}}}}}'
ingresscontroller.operator.openshift.io/default patched
<laptop-2>$ 
<laptop-2>$ oc patch ingresscontroller/default -n  openshift-ingress-operator  --type=merge -p '{"spec":{"replicas": 3}}'
ingresscontroller.operator.openshift.io/default patched
<laptop-2>$ 
```

## Validate router pods

```bash
<laptop-2>$ oc get po -o wide -n openshift-ingress
NAME                              READY   STATUS    RESTARTS   AGE     IP             NODE                                         NOMINATED NODE   READINESS GATES
router-default-58c44676ff-gvpth   1/1     Running   0          6m21s   10.128.1.40    ip-10-0-157-223.us-west-2.compute.internal   <none>           <none>
router-default-58c44676ff-hft5r   1/1     Running   0          37s     10.130.0.131   ip-10-0-206-223.us-west-2.compute.internal   <none>           <none>
router-default-58c44676ff-lk8vb   1/1     Running   0          6m21s   10.129.0.61    ip-10-0-173-122.us-west-2.compute.internal   <none>           <none>
<laptop-2>$ 
<laptop-2>$ oc get po -o wide -n openshift-ingress |egrep -v $CP_NODES
NAME                              READY   STATUS    RESTARTS   AGE     IP             NODE                                         NOMINATED NODE   READINESS GATES
<laptop-2>$ 
```

Now, as router is moved on the infra nodes, we can continue with [OpenShift registry](Move_Registry_to_ODF_infra_nodes_and_scale.md)
