# Run test workload to validate scheduling


As a final step, we do want to ensure that custom workload is just deployed on the worker nodes. [We added an additional label to the worker nodes and changed the default scheduler accordingly](Create_infra_nodes_masters_and_change_default_scheduler.md) so the expectation is customer workload is not scheduled on infra nodes.

We will use a very simple ```DeploymentConfig``` and scale it up to see where the workload is ending up.

## Create a namespace

```bash
laptop-2>$ oc new-project test-wl
Now using project "test-wl" on server "https://api.iscsi-demo.emeatam.support:6443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app rails-postgresql-example

to build a new example application in Ruby. Or use kubectl to deploy a simple Kubernetes application:

    kubectl create deployment hello-node --image=k8s.gcr.io/serve_hostname

<laptop-2>$ 
```

## Create simple deploymenconfig

```bash
<laptop-2>$ cat workload/01-hello-openshift-deploy.yaml 
---
kind: DeploymentConfig
apiVersion: apps.openshift.io/v1
metadata:
  name: hello-openshift
spec:
  replicas: 50
  template:
    metadata:
      labels:
        app: hello-openshift
    spec:
      containers:
      - name: hello-openshift
        image: openshift/hello-openshift:latest
        ports:
        - containerPort: 80
<laptop-2>$ 
<laptop-2>$ oc create -f workload/01-hello-openshift-deploy.yaml 
deploymentconfig.apps.openshift.io/hello-openshift created
<laptop-2>$ 
```

### check where workload is running

```bash
<laptop-2>$ oc get po -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP             NODE                                         NOMINATED NODE   READINESS GATES
hello-openshift-1-24q2d    1/1     Running   0          17s   10.131.0.147   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-28wzm    1/1     Running   0          17s   10.128.2.56    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-2gl9h    1/1     Running   0          17s   10.131.0.146   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-2hszt    1/1     Running   0          17s   10.128.2.61    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-4l7cs    1/1     Running   0          17s   10.131.0.133   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-4pk7r    1/1     Running   0          17s   10.128.2.53    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-5jlvz    1/1     Running   0          17s   10.131.0.153   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-5xn9z    1/1     Running   0          17s   10.131.0.149   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-6qrcj    1/1     Running   0          17s   10.128.2.57    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-6w4qs    1/1     Running   0          17s   10.128.2.62    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-7cjtz    1/1     Running   0          17s   10.128.2.68    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-846r5    1/1     Running   0          17s   10.131.0.134   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-8gdjb    1/1     Running   0          17s   10.128.2.50    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-964kt    1/1     Running   0          17s   10.131.0.138   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-988j2    1/1     Running   0          17s   10.131.0.131   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-9f8s5    1/1     Running   0          17s   10.128.2.65    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-b8vw2    1/1     Running   0          17s   10.131.0.135   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-cbwlk    1/1     Running   0          17s   10.128.2.54    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-deploy   1/1     Running   0          20s   10.128.2.45    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-dntlg    1/1     Running   0          17s   10.131.0.143   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-f6mtm    1/1     Running   0          17s   10.131.0.151   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-fktcx    1/1     Running   0          17s   10.128.2.69    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-fnqzj    1/1     Running   0          17s   10.128.2.59    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-g9rq2    1/1     Running   0          17s   10.131.0.155   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-gc6vh    1/1     Running   0          17s   10.128.2.55    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-ggdn8    1/1     Running   0          17s   10.131.0.148   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-gj2wt    1/1     Running   0          17s   10.131.0.137   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-gjbb6    1/1     Running   0          17s   10.128.2.63    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-hft2m    1/1     Running   0          17s   10.128.2.51    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-j4mkp    1/1     Running   0          17s   10.131.0.150   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-k7pjx    1/1     Running   0          17s   10.131.0.145   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-lfhwg    1/1     Running   0          17s   10.131.0.144   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-mc8jd    1/1     Running   0          17s   10.131.0.141   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-mdcxc    1/1     Running   0          17s   10.128.2.67    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-mgtpr    1/1     Running   0          17s   10.131.0.140   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-pfw5t    1/1     Running   0          17s   10.128.2.70    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-pl4wf    1/1     Running   0          17s   10.128.2.66    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-r97sl    1/1     Running   0          17s   10.131.0.154   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-rpnk2    1/1     Running   0          17s   10.131.0.139   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-s6zxp    1/1     Running   0          17s   10.131.0.152   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-s87nc    1/1     Running   0          17s   10.128.2.48    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-sflr5    1/1     Running   0          17s   10.128.2.49    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-sld48    1/1     Running   0          17s   10.128.2.60    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-st4rl    1/1     Running   0          17s   10.128.2.47    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-t48vd    1/1     Running   0          17s   10.131.0.142   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-twxpk    1/1     Running   0          17s   10.128.2.46    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-vbn6x    1/1     Running   0          17s   10.131.0.132   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-wh7nt    1/1     Running   0          17s   10.128.2.52    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-wh87h    1/1     Running   0          17s   10.131.0.136   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-xv525    1/1     Running   0          17s   10.128.2.58    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
hello-openshift-1-xwdds    1/1     Running   0          17s   10.128.2.64    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
<laptop-2>$ 
<laptop-2>$ oc get po  -o wide |egrep $CP_NODES
<laptop-2>$ 
```

## scale further and validate

```bash
<laptop-2>$ oc scale deploymentconfig hello-openshift  --replicas=1000
W1122 18:04:26.516949  500153 warnings.go:70] extensions/v1beta1 Scale is deprecated in v1.2+, unavailable in v1.16+
deploymentconfig.apps.openshift.io/hello-openshift scaled
<laptop-2>$ 
<laptop-2>$ oc get po  -o wide |grep Running |wc -l 
433
<laptop-2>$
<laptop-2>$ oc get po  -o wide |egrep $CP_NODES
<laptop-2>$ 
```

Even after waiting a log time we will not have more than the 433 pods Running shown, why is this ?

```bash
<laptop-2>$ oc get po -o wide |grep ip-10-0-148-134.us-west-2.compute.internal |wc -l 
227
<laptop-2>$ oc get po -o wide -A |grep ip-10-0-148-134.us-west-2.compute.internal |wc -l 
250
<laptop-2>$ 
<laptop-2>$ oc get po -o wide |grep ip-10-0-177-190.us-west-2.compute.internal |wc -l 
234
<laptop-2>$ 
<laptop-2>$ oc get po -o wide -A |grep ip-10-0-177-190.us-west-2.compute.internal |wc -l 
<laptop-2>$ oc get po -o wide |grep Pending|wc -l 
539
<laptop-2>$ 
```

As we can see, we have 250 pods per node max (the normally set max pods per node in kubelet). As there are other pods running as well (multus, sdn,node-exporter,..) we cannot get even to the 500 custom pods scheduled. On the plus side, the pods aren't scheduled on the infra nodes either ;)


Last step is to [upgrade the cluster](Upgrade.md) to see if this is working fine as well
