# Deploy logging to infra nodes and ODF

The last component we are deploying on top of the infra nodes and ODF is logging which we need to deploy from the beginning.

References:
* [Infrastructure Nodes in OpenShift 4](https://access.redhat.com/solutions/5034771)
* [Installing Logging | Logging | OpenShift Container Platform 4.8](https://docs.openshift.com/container-platform/4.8/logging/cluster-logging-deploying.html#cluster-logging-deploy-cli_cluster-logging-deploying)
* [Configure storage for OpenShift Container Platform services Red Hat OpenShift Container Storage 4.8 | Red Hat Customer Portal](https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.8/html/managing_and_allocating_storage_resources/configure-storage-for-openshift-container-platform-services_rhocs#cluster-logging-for-openshift-container-storage_rhocs)
  

Logging is not installed with initial OCP deployment, hence we deploy and configure it in one go.

Files are provided in folder logging, whou might change them as needed. In case logging is alredy deployed, mind to modify existing ```ClusterLogging``` rather ten applying the below one to prevent unwanted config changes

## Files in folder

```bash
<laptop-2>$ ll logging/
total 28
-rw-rw-r--. 1 dm dm 184 Nov 21 11:39 01-logging-namespace-es.yaml
-rw-rw-r--. 1 dm dm 175 Nov 21 11:39 02-logging-namespace-clo.yaml
-rw-rw-r--. 1 dm dm 154 Nov 21 11:39 03-logging-og-es.yaml
-rw-rw-r--. 1 dm dm 320 Nov 21 11:39 04-logging-subs-eso.yaml
-rw-rw-r--. 1 dm dm 173 Nov 21 11:39 05-logging-og-clo.yaml
-rw-rw-r--. 1 dm dm 252 Nov 21 11:39 06-logging-subs-clo.yaml
-rw-rw-r--. 1 dm dm 972 Nov 21 11:39 07-logging-clo-instance.yaml
<laptop-2>$ 
```

We follow the official documentation in the next steps

## Create components for elasticsearch and logging

```bash
<laptop-2>$ cat logging/01-logging-namespace-es.yaml 
---
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-operators-redhat
  annotations:
    openshift.io/node-selector: ""
  labels:
    openshift.io/cluster-monitoring: "true"
<laptop-2>$ 
<laptop-2>$ oc create -f logging/01-logging-namespace-es.yaml
namespace/openshift-operators-redhat created
<laptop-2>$ 
<laptop-2>$ cat logging/02-logging-namespace-clo.yaml 
---
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-logging
  annotations:
    openshift.io/node-selector: ""
  labels:
    openshift.io/cluster-monitoring: "true"
<laptop-2>$ 
<laptop-2>$ oc create -f logging/02-logging-namespace-clo.yaml 
namespace/openshift-logging created
<laptop-2>$ 
<laptop-2>$ cat logging/03-logging-og-es.yaml 
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-operators-redhat
  namespace: openshift-operators-redhat
spec: {}
<laptop-2>$ 
<laptop-2>$ oc create -f logging/03-logging-og-es.yaml 
operatorgroup.operators.coreos.com/openshift-operators-redhat created
<laptop-2>$ 
<laptop-2>$ cat logging/04-logging-subs-eso.yaml 
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: "elasticsearch-operator"
  namespace: "openshift-operators-redhat"
spec:
  channel: "stable-5.3"
  installPlanApproval: "Automatic"
  source: "redhat-operators"
  sourceNamespace: "openshift-marketplace"
  name: "elasticsearch-operator"
<laptop-2>$ 
<laptop-2>$ oc create -f logging/04-logging-subs-eso.yaml
subscription.operators.coreos.com/elasticsearch-operator created
<laptop-2>$ 
<laptop-2>$ cat logging/05-logging-og-clo.yaml 
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: cluster-logging
  namespace: openshift-logging
spec:
  targetNamespaces:
  - openshift-logging
<laptop-2>$ 
<laptop-2>$ oc create -f logging/05-logging-og-clo.yaml
operatorgroup.operators.coreos.com/cluster-logging created
<laptop-2>$ 
<laptop-2>$ cat logging/06-logging-subs-clo.yaml 
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: cluster-logging
  namespace: openshift-logging
spec:
  channel: "stable-5.3"
  name: cluster-logging
  source: redhat-operators
  sourceNamespace: openshift-marketplace
<laptop-2>$ 
<laptop-2>$ oc create -f logging/06-logging-subs-clo.yaml
subscription.operators.coreos.com/cluster-logging created
<laptop-2>$ 
```

## Confirm created objects/resources are available

```bash
<laptop-2>$ oc get po,og,subs -n openshift-logging
NAME                                            READY   STATUS    RESTARTS   AGE
pod/cluster-logging-operator-55c7dc97c9-5k9cb   1/1     Running   0          15s

NAME                                                 AGE
operatorgroup.operators.coreos.com/cluster-logging   42s

NAME                                                PACKAGE           SOURCE             CHANNEL
subscription.operators.coreos.com/cluster-logging   cluster-logging   redhat-operators   stable-5.3
<laptop-2>$ 
<laptop-2>$ oc get po,og,subs -n openshift-operators-redhat
NAME                                         READY   STATUS    RESTARTS   AGE
pod/elasticsearch-operator-b57bf88b6-8bhh6   2/2     Running   0          67s

NAME                                                            AGE
operatorgroup.operators.coreos.com/openshift-operators-redhat   110s

NAME                                                       PACKAGE                  SOURCE             CHANNEL
subscription.operators.coreos.com/elasticsearch-operator   elasticsearch-operator   redhat-operators   stable-5.3
<laptop-2>$ 
```

## Create logging instance

```bash
<laptop-2>$ cat logging/07-logging-clo-instance.yaml 
---
apiVersion: "logging.openshift.io/v1"
kind: "ClusterLogging"
metadata:
  name: "instance"
  namespace: "openshift-logging"
spec:
  managementState: "Managed"
  logStore:
    type: "elasticsearch"
    retentionPolicy:
      application:
        maxAge: 1d
      infra:
        maxAge: 7d
      audit:
        maxAge: 7d
    elasticsearch:
      nodeCount: 3
      nodeSelector:
        node-role.kubernetes.io/infra: ''
      storage:
        storageClassName: "ocs-storagecluster-ceph-rbd"
        size: 200G
      resources:
        limits:
          memory: "16Gi"
        requests:
          memory: "16Gi"
      proxy:
        resources:
          limits:
            memory: 256Mi
          requests:
             memory: 256Mi
      redundancyPolicy: "SingleRedundancy"
  visualization:
    type: "kibana"
    kibana:
      nodeSelector:
        node-role.kubernetes.io/infra: ''
      replicas: 1
  collection:
    logs:
      type: "fluentd"
      fluentd: {}
<laptop-2>$ 
<laptop-2>$ oc create -f logging/07-logging-clo-instance.yaml 
clusterlogging.logging.openshift.io/instance created
<laptop-2>$ 
```

## Validate components location

```bash
<laptop-2>$ oc get po,pvc -o wide -n openshift-logging
NAME                                                READY   STATUS    RESTARTS   AGE     IP             NODE                                         NOMINATED NODE   READINESS GATES
pod/cluster-logging-operator-55c7dc97c9-5k9cb       1/1     Running   0          2m53s   10.128.1.77    ip-10-0-157-223.us-west-2.compute.internal   <none>           <none>
pod/collector-2fln8                                 2/2     Running   0          46s     10.131.0.105   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
pod/collector-6pb9t                                 2/2     Running   0          51s     10.128.2.18    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
pod/collector-fszpp                                 2/2     Running   0          57s     10.128.1.82    ip-10-0-157-223.us-west-2.compute.internal   <none>           <none>
pod/collector-sbtpj                                 2/2     Running   0          47s     10.129.0.73    ip-10-0-173-122.us-west-2.compute.internal   <none>           <none>
pod/collector-zsqz2                                 2/2     Running   0          39s     10.130.0.146   ip-10-0-206-223.us-west-2.compute.internal   <none>           <none>
pod/elasticsearch-cdm-xvkwmw6u-1-749c9f6d8c-bqrz6   2/2     Running   0          82s     10.130.0.144   ip-10-0-206-223.us-west-2.compute.internal   <none>           <none>
pod/elasticsearch-cdm-xvkwmw6u-2-7bb786b44-2tw79    2/2     Running   0          81s     10.129.0.71    ip-10-0-173-122.us-west-2.compute.internal   <none>           <none>
pod/elasticsearch-cdm-xvkwmw6u-3-d4976ccd9-77xsp    2/2     Running   0          80s     10.128.1.80    ip-10-0-157-223.us-west-2.compute.internal   <none>           <none>
pod/kibana-85d8659878-qjrc7                         2/2     Running   0          82s     10.128.1.79    ip-10-0-157-223.us-west-2.compute.internal   <none>           <none>

NAME                                                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                  AGE   VOLUMEMODE
persistentvolumeclaim/elasticsearch-elasticsearch-cdm-xvkwmw6u-1   Bound    pvc-ba8bea9a-653b-486e-98f8-426a80441a3b   187Gi      RWO            ocs-storagecluster-ceph-rbd   82s   Filesystem
persistentvolumeclaim/elasticsearch-elasticsearch-cdm-xvkwmw6u-2   Bound    pvc-26434b22-bcf9-4173-8c73-f6e3ba3ee4f3   187Gi      RWO            ocs-storagecluster-ceph-rbd   82s   Filesystem
persistentvolumeclaim/elasticsearch-elasticsearch-cdm-xvkwmw6u-3   Bound    pvc-af7ac0ba-0f88-4612-9a90-2957e7c38e76   187Gi      RWO            ocs-storagecluster-ceph-rbd   82s   Filesystem
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ oc get po -o wide -n openshift-logging|egrep -v $CP_NODES
NAME                                            READY   STATUS    RESTARTS   AGE     IP             NODE                                         NOMINATED NODE   READINESS GATES
collector-2fln8                                 2/2     Running   0          77s     10.131.0.105   ip-10-0-177-190.us-west-2.compute.internal   <none>           <none>
collector-6pb9t                                 2/2     Running   0          82s     10.128.2.18    ip-10-0-148-134.us-west-2.compute.internal   <none>           <none>
<laptop-2>$ 
```

Core components are now running on infra nodes as well so we can now validate that [custom workload it is not deployed on the masters](Run_test_workload_to_validate_scheduling.md)


