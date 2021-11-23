# Move monitoring to infra nodes and ODF

References:
* [Infrastructure Nodes in OpenShift 4](https://access.redhat.com/solutions/5034771)
* [Configuring monitoring to use OpenShift Container Storage](https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.8/html/managing_and_allocating_storage_resources/configure-storage-for-openshift-container-platform-services_rhocs#configuring-monitoring-to-use-openshift-container-storage_rhocs)]
* [Moving the monitoring solution](https://docs.openshift.com/container-platform/4.8/machine_management/creating-infrastructure-machinesets.html#infrastructure-moving-monitoring_creating-infrastructure-machinesets)

Moving monitoring to infra nodes basically just required chaching the current ```ConfigMap```

for OpenShift monitoring. Please be aware, if you have already modified monitoring to not overwrite it with the below ```ConfigMap``` but rather expert, change and apply it again.

Please refer to the following docs for further information:

* [[Configuring the monitoring stack | Monitoring | OpenShift Container Platform 4.8](https://docs.openshift.com/container-platform/4.8/monitoring/configuring-the-monitoring-stack.html)
  
* [Chapter 4. Configure storage for OpenShift Container Platform services Red Hat OpenShift Container Storage 4.8 | Red Hat Customer Portal](https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.8/html/managing_and_allocating_storage_resources/configure-storage-for-openshift-container-platform-services_rhocs#configuring-monitoring-to-use-openshift-container-storage_rhocs)
  

### Check where monitoring pods are running

```bash
<laptop-2>$ oc get po -o wide -n openshift-monitoring 
NAME                                           READY   STATUS    RESTARTS   AGE    IP             NODE                                         NOMINATED NODE   READINESS GATES
alertmanager-main-0                            5/5     Running   0          21h    10.128.2.9     ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
alertmanager-main-1                            5/5     Running   0          21h    10.131.0.17    ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
alertmanager-main-2                            5/5     Running   0          21h    10.128.2.10    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
cluster-monitoring-operator-84f695985d-2dqft   2/2     Running   0          17h    10.130.0.19    ip-10-0-206-223.us-west-2.compute.internal   <none>           <none>
grafana-5dbdd585c6-kd7sn                       2/2     Running   0          21h    10.128.2.11    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
kube-state-metrics-784f4f658-ksktx             3/3     Running   0          21h    10.131.0.10    ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
node-exporter-92zmk                            2/2     Running   0          21h    10.0.177.190   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
node-exporter-9xvcr                            2/2     Running   2          21h    10.0.173.122   ip-10-0-173-122.us-west-2.compute.internal   <none>           <none>
node-exporter-jr96x                            2/2     Running   0          21h    10.0.148.134   ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
node-exporter-r9skz                            2/2     Running   2          21h    10.0.157.223   ip-10-0-157-223.us-west-2.compute.internal   <none>           <none>
node-exporter-x6fvh                            2/2     Running   2          21h    10.0.206.223   ip-10-0-206-223.us-west-2.compute.internal   <none>           <none>
openshift-state-metrics-869fc5654c-5qfhc       3/3     Running   0          21h    10.131.0.16    ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
prometheus-adapter-5464cc9846-2t7zs            1/1     Running   0          151m   10.128.2.15    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
prometheus-adapter-5464cc9846-b9kdf            1/1     Running   0          151m   10.130.0.116   ip-10-0-206-223.us-west-2.compute.internal   <none>           <none>
prometheus-k8s-0                               7/7     Running   1          21h    10.131.0.19    ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
prometheus-k8s-1                               7/7     Running   1          21h    10.128.2.13    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
prometheus-operator-7c68b985bb-nv6mz           2/2     Running   0          17h    10.129.0.24    ip-10-0-173-122.us-west-2.compute.internal   <none>           <none>
telemeter-client-688cf9cbb6-4g92d              3/3     Running   0          21h    10.131.0.6     ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
thanos-querier-56c6d5db97-9nm67                5/5     Running   0          21h    10.128.2.12    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
thanos-querier-56c6d5db97-sw7qs                5/5     Running   0          21h    10.131.0.18    ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
<laptop-2>$ 
<laptop-2>$ oc get po -o wide -n openshift-monitoring |egrep -v $CP_NODES
NAME                                           READY   STATUS    RESTARTS   AGE    IP             NODE                                         NOMINATED NODE   READINESS GATES
alertmanager-main-0                            5/5     Running   0          21h    10.128.2.9     ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
alertmanager-main-1                            5/5     Running   0          21h    10.131.0.17    ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
alertmanager-main-2                            5/5     Running   0          21h    10.128.2.10    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
grafana-5dbdd585c6-kd7sn                       2/2     Running   0          21h    10.128.2.11    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
kube-state-metrics-784f4f658-ksktx             3/3     Running   0          21h    10.131.0.10    ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
node-exporter-92zmk                            2/2     Running   0          21h    10.0.177.190   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
node-exporter-jr96x                            2/2     Running   0          21h    10.0.148.134   ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
openshift-state-metrics-869fc5654c-5qfhc       3/3     Running   0          21h    10.131.0.16    ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
prometheus-adapter-5464cc9846-2t7zs            1/1     Running   0          151m   10.128.2.15    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
prometheus-k8s-0                               7/7     Running   1          21h    10.131.0.19    ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
prometheus-k8s-1                               7/7     Running   1          21h    10.128.2.13    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
telemeter-client-688cf9cbb6-4g92d              3/3     Running   0          21h    10.131.0.6     ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
thanos-querier-56c6d5db97-9nm67                5/5     Running   0          21h    10.128.2.12    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
thanos-querier-56c6d5db97-sw7qs                5/5     Running   0          21h    10.131.0.18    ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
<laptop-2>$ 
```

### Create and apply config map

**<mark>Mind</mark>**: if you changed your monitoring stack already, do not blindly apply the below, but change your existing config accordingly

```bash
<laptop-2>$ cat monitoring/01-configmap-with-storage-and-infra.yaml 
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    alertmanagerMain:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      volumeClaimTemplate:
        metadata:
          name: ocs-alertmanager-claim
        spec:
          storageClassName: ocs-storagecluster-ceph-rbd
          resources:
            requests:
              storage: 40Gi
    prometheusK8s:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
      retention: 24h
      volumeClaimTemplate:
        metadata:
          name: ocs-prometheus-claim
        spec:
          storageClassName: ocs-storagecluster-ceph-rbd
          resources:
            requests:
              storage: 40Gi
    prometheusOperator:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    grafana:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    k8sPrometheusAdapter:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    kubeStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    telemeterClient:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    openshiftStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    thanosQuerier:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
<laptop-2>$ 
<laptop-2>$ oc create -f monitoring/01-configmap-with-storage-and-infra.yaml
configmap/cluster-monitoring-config created
<laptop-2>$ 
```

## Validate components

After some time PVCs should be created and pods should run on infra nodes

As only expected pods are now running on the worker nodes, we can move on to [deploying logging on top of ODF and infra nodes](Deploy_logging_to_infra_nodes_and_ODF.md)
