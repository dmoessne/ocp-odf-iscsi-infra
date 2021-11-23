# Create install-config.yaml and deploy cluster

Reference:
* [Installing a cluster on AWS with customizations](https://docs.openshift.com/container-platform/4.8/installing/installing_aws/installing-aws-customizations.html)


The next step is to create a ```install-config.yaml``` wither via the ```openshift-installer``` or from below template. A ssh key is added to allow connecting later on via the bastion and a pull secret is needed as well which can be fetched from [Red Hat OpenShift Cluster Manager](https://console.redhat.com/openshift/create) (login required)

We will not make masters schedulabe at this time, but later on, so in case someone follows this and has dedicated infra nodes this set can then be skipped. However, to have all the infra workload on top of the masters, we need tho have more than the usual resources and hence create ```m5.12xlarge```

## install-config.yaml

The created file looks as follows

```bash
<laptop>$ cat install-config.yaml 
apiVersion: v1
baseDomain: emeatam.support
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 2
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform: 
    aws:
      type: m5.12xlarge
  replicas: 3
metadata:
  creationTimestamp: null
  name: iscsi-demo
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  aws:
    region: us-west-2
    userTags:
      user: dmoessne
      project: iscsi-demo
publish: External
pullSecret: '<redacted>'
sshKey: |
  ssh-rsa <redacted>
<laptop>$ 
```

## Deploy cluster

In order to keep the created ```install-config.yaml``` we create a separate folder named ```cluster/``` where we copy the file over and start deployment from there:

```bash
<laptop>$ cp install-config.yaml cluster/
<laptop>$ 
<laptop>$ openshift-install create cluster --dir cluster/
INFO Credentials loaded from the "default" profile in file "/home/dm/.aws/credentials" 
INFO Consuming Install Config from target directory 
WARNING Following quotas ec2/L-0263D0A3 (us-west-2) are available but will be completely used pretty soon. 
INFO Creating infrastructure resources...         
INFO Waiting up to 20m0s for the Kubernetes API at https://api.iscsi-demo.emeatam.support:6443... 
INFO API v1.21.1+6438632 up                       
INFO Waiting up to 30m0s for bootstrapping to complete... 
INFO Destroying the bootstrap resources...        
INFO Waiting up to 40m0s for the cluster at https://api.iscsi-demo.emeatam.support:6443 to initialize... 
W1121 12:18:08.830014  468168 reflector.go:436] k8s.io/client-go/tools/watch/informerwatcher.go:146: watch of *v1.ClusterVersion ended with: an error on the server ("unable to decode an event from the watch stream: http2: client connection lost") has prevented the request from succeeding
INFO Waiting up to 10m0s for the openshift-console route to be created... 
INFO Install complete!                            
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/home/dm/demo/cluster/auth/kubeconfig' 
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.iscsi-demo.emeatam.support 
INFO Login to the console with user: "kubeadmin", and password: "vDsFw-mJ4mg-DBkYD-8o2d5" 
INFO Time elapsed: 42m50s                         
<laptop>$ 
```

## Validate install

Once this is complete we briefly check all cluster operators are up and running as node

```bash
<laptop>$ export KUBECONFIG=/home/dm/demo/cluster/auth/kubeconfig
<laptop>$ oc get co 
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
authentication                             4.8.18    True        False         False      31m
baremetal                                  4.8.18    True        False         False      58m
cloud-credential                           4.8.18    True        False         False      63m
cluster-autoscaler                         4.8.18    True        False         False      57m
config-operator                            4.8.18    True        False         False      59m
console                                    4.8.18    True        False         False      46m
csi-snapshot-controller                    4.8.18    True        False         False      59m
dns                                        4.8.18    True        False         False      58m
etcd                                       4.8.18    True        False         False      57m
image-registry                             4.8.18    True        False         False      52m
ingress                                    4.8.18    True        False         False      51m
insights                                   4.8.18    True        False         False      52m
kube-apiserver                             4.8.18    True        False         False      55m
kube-controller-manager                    4.8.18    True        False         False      56m
kube-scheduler                             4.8.18    True        False         False      56m
kube-storage-version-migrator              4.8.18    True        False         False      59m
machine-api                                4.8.18    True        False         False      53m
machine-approver                           4.8.18    True        False         False      58m
machine-config                             4.8.18    True        False         False      58m
marketplace                                4.8.18    True        False         False      58m
monitoring                                 4.8.18    True        False         False      51m
network                                    4.8.18    True        False         False      59m
node-tuning                                4.8.18    True        False         False      58m
openshift-apiserver                        4.8.18    True        False         False      54m
openshift-controller-manager               4.8.18    True        False         False      58m
openshift-samples                          4.8.18    True        False         False      55m
operator-lifecycle-manager                 4.8.18    True        False         False      58m
operator-lifecycle-manager-catalog         4.8.18    True        False         False      58m
operator-lifecycle-manager-packageserver   4.8.18    True        False         False      54m
service-ca                                 4.8.18    True        False         False      59m
storage                                    4.8.18    True        False         False      58m
<laptop>$ 
<laptop>$ oc get nodes
NAME                                         STATUS   ROLES    AGE   VERSION
ip-10-0-148-134.us-west-2.compute.internal   Ready    worker   53m   v1.21.1+6438632
ip-10-0-157-223.us-west-2.compute.internal   Ready    master   60m   v1.21.1+6438632
ip-10-0-173-122.us-west-2.compute.internal   Ready    master   60m   v1.21.1+6438632
ip-10-0-177-190.us-west-2.compute.internal   Ready    worker   54m   v1.21.1+6438632
ip-10-0-206-223.us-west-2.compute.internal   Ready    master   60m   v1.21.1+6438632
<laptop>$ 
```

Having the cluster set up we're going to set up a [jumhost and an iscsi host](Set_up_bastion_and_iscsi_host.md)
