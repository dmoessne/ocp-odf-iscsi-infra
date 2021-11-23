# Login to target and automate this via mc

References:
* [Enabling multipathing with kernel arguments on RHCOS](https://docs.openshift.com/container-platform/4.8/post_installation_configuration/machine-configuration-tasks.html#rhcos-enabling-multipath-day-2_post-install-machine-configuration-tasks)
* [iSCSI Multipathing is not working on Openshift Container Platform](https://access.redhat.com/solutions/6366371)


## Login to target from masters

Login to iscsi target from nodes (manually)

Back to window 2 we are going to log into every master node and validate iscsi target login

```bash
<laptop-2>$ oc get no -l node-role.kubernetes.io/master 
NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-0-157-223.us-west-2.compute.internal   Ready    master   3h9m    v1.21.1+6438632
ip-10-0-173-122.us-west-2.compute.internal   Ready    master   3h10m   v1.21.1+6438632
ip-10-0-206-223.us-west-2.compute.internal   Ready    master   3h9m    v1.21.1+6438632
<laptop-2>$ 
<laptop-2>$ oc debug node/ip-10-0-157-223.us-west-2.compute.internal
Starting pod/ip-10-0-157-223us-west-2computeinternal-debug ...
To use host binaries, run `chroot /host`
Pod IP: 10.0.157.223
If you don't see a command prompt, try pressing enter.
sh-4.4# 
sh-4.4# chroot /host
sh-4.4# iscsiadm -m discovery -t st -p 10.0.147.203
10.0.147.203:3260,1 iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb
sh-4.4# iscsiadm -m discovery -t st -p 10.0.147.46 
10.0.147.46:3260,1 iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb
sh-4.4# 
sh-4.4# iscsiadm --mode node --target iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb --portal 10.0.147.203 -l    
Logging in to [iface: default, target: iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb, portal: 10.0.147.203,3260]
Login to [iface: default, target: iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb, portal: 10.0.147.203,3260] successful.
sh-4.4# 
sh-4.4# iscsiadm --mode node --target iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb --portal 10.0.147.46 -l 
Logging in to [iface: default, target: iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb, portal: 10.0.147.46,3260]
Login to [iface: default, target: iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb, portal: 10.0.147.46,3260] successful.
sh-4.4# 
sh-4.4# lsblk 
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda           8:0    0     1T  0 disk 
sdb           8:16   0     1T  0 disk 
nvme0n1     259:0    0   120G  0 disk 
|-nvme0n1p1 259:1    0     1M  0 part 
|-nvme0n1p2 259:2    0   127M  0 part 
|-nvme0n1p3 259:3    0   384M  0 part /boot
`-nvme0n1p4 259:4    0 119.5G  0 part /sysroot
sh-4.4# 
sh-4.4# 
sh-4.4# exit
sh-4.4# exit
Removing debug pod ...

<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ oc debug node/ip-10-0-173-122.us-west-2.compute.internal
Starting pod/ip-10-0-173-122us-west-2computeinternal-debug ...
To use host binaries, run `chroot /host`
Pod IP: 10.0.173.122
If you don't see a command prompt, try pressing enter.
sh-4.4# chroot /host
sh-4.4# 
sh-4.4# iscsiadm -m discovery -t st -p 10.0.147.203
10.0.147.203:3260,1 iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb
sh-4.4# iscsiadm -m discovery -t st -p 10.0.147.46 
10.0.147.46:3260,1 iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb
sh-4.4# 
sh-4.4# iscsiadm --mode node --target iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb --portal 10.0.147.203 -l    
Logging in to [iface: default, target: iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb, portal: 10.0.147.203,3260]
Login to [iface: default, target: iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb, portal: 10.0.147.203,3260] successful.
sh-4.4# iscsiadm --mode node --target iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb --portal 10.0.147.46 -l 
Logging in to [iface: default, target: iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb, portal: 10.0.147.46,3260]
Login to [iface: default, target: iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb, portal: 10.0.147.46,3260] successful.
sh-4.4# 
sh-4.4# lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda           8:0    0     1T  0 disk 
sdb           8:16   0     1T  0 disk 
nvme0n1     259:0    0   120G  0 disk 
|-nvme0n1p1 259:1    0     1M  0 part 
|-nvme0n1p2 259:2    0   127M  0 part 
|-nvme0n1p3 259:3    0   384M  0 part /boot
`-nvme0n1p4 259:4    0 119.5G  0 part /sysroot
sh-4.4# exit
sh-4.4# exit

Removing debug pod ...
<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ oc debug node/ip-10-0-206-223.us-west-2.compute.internal
Starting pod/ip-10-0-206-223us-west-2computeinternal-debug ...
To use host binaries, run `chroot /host`
Pod IP: 10.0.206.223
If you don't see a command prompt, try pressing enter.
sh-4.4# chroot /host
sh-4.4# 
sh-4.4# iscsiadm -m discovery -t st -p 10.0.147.203
10.0.147.203:3260,1 iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb
sh-4.4# iscsiadm -m discovery -t st -p 10.0.147.46 
10.0.147.46:3260,1 iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb
sh-4.4# 
sh-4.4# iscsiadm --mode node --target iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb --portal 10.0.147.203 -l    
Logging in to [iface: default, target: iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb, portal: 10.0.147.203,3260]
Login to [iface: default, target: iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb, portal: 10.0.147.203,3260] successful.
sh-4.4# iscsiadm --mode node --target iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb --portal 10.0.147.46 -l 
Logging in to [iface: default, target: iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb, portal: 10.0.147.46,3260]
Login to [iface: default, target: iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb, portal: 10.0.147.46,3260] successful.
sh-4.4# 
sh-4.4# lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda           8:0    0     1T  0 disk 
sdb           8:16   0     1T  0 disk 
nvme0n1     259:0    0   120G  0 disk 
|-nvme0n1p1 259:1    0     1M  0 part 
|-nvme0n1p2 259:2    0   127M  0 part 
|-nvme0n1p3 259:3    0   384M  0 part /boot
`-nvme0n1p4 259:4    0 119.5G  0 part /sysroot
sh-4.4# exit
sh-4.4# exit
```

## Setup iscsi and multipathing

Currently we have no multipathing running and if we would now reboot the master nodes, iscsi logins would be gone as well as iscsid is not started and iscsi autologin (iscsi) would also not start automatically.

So we will create a mc that

* has a valid multipath.conf
  
* starts iscsid
  
* starts iscsi (for autologin to target)
  

### Create multipath.cong

We will use a very simple multipath.conf that will do the trick for us here:

```bash
<laptop-2>$ cat iscsi/multipath.conf
# device-mapper-multipath configuration file

# For a complete list of the default configuration values, run either:
# # multipath -t
# or
# # multipathd show config

# For a list of configuration options with descriptions, see the
# multipath.conf man page.

defaults {
    user_friendly_names yes
    find_multipaths yes
    enable_foreign "^$"
}

blacklist_exceptions {
        property "(SCSI_IDENT_|ID_WWN)"
}

blacklist {
}
<laptop-2>$ 
```

In order to get deployed via mc we would need is base64 encoded:

```bash
<laptop-2>$ cat iscsi/multipath.conf|base64 -w0
IyBkZXZpY2UtbWFwcGVyLW11bHRpcGF0aCBjb25maWd1cmF0aW9uIGZpbGUKCiMgRm9yIGEgY29tcGxldGUgbGlzdCBvZiB0aGUgZGVmYXVsdCBjb25maWd1cmF0aW9uIHZhbHVlcywgcnVuIGVpdGhlcjoKIyAjIG11bHRpcGF0aCAtdAojIG9yCiMgIyBtdWx0aXBhdGhkIHNob3cgY29uZmlnCgojIEZvciBhIGxpc3Qgb2YgY29uZmlndXJhdGlvbiBvcHRpb25zIHdpdGggZGVzY3JpcHRpb25zLCBzZWUgdGhlCiMgbXVsdGlwYXRoLmNvbmYgbWFuIHBhZ2UuCgpkZWZhdWx0cyB7Cgl1c2VyX2ZyaWVuZGx5X25hbWVzIHllcwoJZmluZF9tdWx0aXBhdGhzIHllcwoJZW5hYmxlX2ZvcmVpZ24gIl4kIgp9CgpibGFja2xpc3RfZXhjZXB0aW9ucyB7CiAgICAgICAgcHJvcGVydHkgIihTQ1NJX0lERU5UX3xJRF9XV04pIgp9CgpibGFja2xpc3Qgewp9Cg==<laptop-2>$ 
<laptop-2>$ 
```

### Create mc

With the encoded multipathconf and being aware that we need also start miltipathd, iscsid and iscsi the resulting mc looks as follows:

(*Mind* the below mc is for the masters - as we want this to be run on the masters in our example. If you want a different node type. change accordingly )

```bash
<laptop-2>$ cat iscsi/multipath.conf|base64 -w0
IyBkZXZpY2UtbWFwcGVyLW11bHRpcGF0aCBjb25maWd1cmF0aW9uIGZpbGUKCiMgRm9yIGEgY29tcGxldGUgbGlzdCBvZiB0aGUgZGVmYXVsdCBjb25maWd1cmF0aW9uIHZhbHVlcywgcnVuIGVpdGhlcjoKIyAjIG11bHRpcGF0aCAtdAojIG9yCiMgIyBtdWx0aXBhdGhkIHNob3cgY29uZmlnCgojIEZvciBhIGxpc3Qgb2YgY29uZmlndXJhdGlvbiBvcHRpb25zIHdpdGggZGVzY3JpcHRpb25zLCBzZWUgdGhlCiMgbXVsdGlwYXRoLmNvbmYgbWFuIHBhZ2UuCgpkZWZhdWx0cyB7Cgl1c2VyX2ZyaWVuZGx5X25hbWVzIHllcwoJZmluZF9tdWx0aXBhdGhzIHllcwoJZW5hYmxlX2ZvcmVpZ24gIl4kIgp9CgpibGFja2xpc3RfZXhjZXB0aW9ucyB7CiAgICAgICAgcHJvcGVydHkgIihTQ1NJX0lERU5UX3xJRF9XV04pIgp9CgpibGFja2xpc3Qgewp9Cg==<laptop-2>$ 
<laptop-2>$ 
<laptop-2>$ cat iscsi/iscsi-mc.yaml 
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-iscsi-multipathing
spec:
  config:
    ignition: 
      version: 2.2.0
    storage:
      files:
      - contents:
         source: data:text/plain;charset=utf-8;base64,IyBkZXZpY2UtbWFwcGVyLW11bHRpcGF0aCBjb25maWd1cmF0aW9uIGZpbGUKCiMgRm9yIGEgY29tcGxldGUgbGlzdCBvZiB0aGUgZGVmYXVsdCBjb25maWd1cmF0aW9uIHZhbHVlcywgcnVuIGVpdGhlcjoKIyAjIG11bHRpcGF0aCAtdAojIG9yCiMgIyBtdWx0aXBhdGhkIHNob3cgY29uZmlnCgojIEZvciBhIGxpc3Qgb2YgY29uZmlndXJhdGlvbiBvcHRpb25zIHdpdGggZGVzY3JpcHRpb25zLCBzZWUgdGhlCiMgbXVsdGlwYXRoLmNvbmYgbWFuIHBhZ2UuCgpkZWZhdWx0cyB7Cgl1c2VyX2ZyaWVuZGx5X25hbWVzIHllcwoJZmluZF9tdWx0aXBhdGhzIHllcwoJZW5hYmxlX2ZvcmVpZ24gIl4kIgp9CgpibGFja2xpc3RfZXhjZXB0aW9ucyB7CiAgICAgICAgcHJvcGVydHkgIihTQ1NJX0lERU5UX3xJRF9XV04pIgp9CgpibGFja2xpc3Qgewp9Cg==
        filesystem: root
        mode: 420
        path: /etc/multipath.conf
    systemd:
      units:
      - name: iscsid.service
        enabled: true
      - name: iscsi.service
        enabled: true
      - name: multipathd.service
        enabled: true
<laptop-2>$ 
```

### Deploy mc

Now we can deploy the mc and will wait for the master nodes to be restarted:

```bash
<laptop-2>$ oc create -f iscsi/iscsi-mc.yaml
machineconfig.machineconfiguration.openshift.io/99-master-iscsi-multipathing created
<laptop-2>$ 
<laptop-2>$ oc get mc
NAME                                               GENERATEDBYCONTROLLER                      IGNITIONVERSION   AGE
00-master                                          3b46a2229b706cc9aa53e3ed86a407fbe3c5dff4   3.2.0             3h28m
00-worker                                          3b46a2229b706cc9aa53e3ed86a407fbe3c5dff4   3.2.0             3h28m
01-master-container-runtime                        3b46a2229b706cc9aa53e3ed86a407fbe3c5dff4   3.2.0             3h28m
01-master-kubelet                                  3b46a2229b706cc9aa53e3ed86a407fbe3c5dff4   3.2.0             3h28m
01-worker-container-runtime                        3b46a2229b706cc9aa53e3ed86a407fbe3c5dff4   3.2.0             3h28m
01-worker-kubelet                                  3b46a2229b706cc9aa53e3ed86a407fbe3c5dff4   3.2.0             3h28m
99-master-generated-registries                     3b46a2229b706cc9aa53e3ed86a407fbe3c5dff4   3.2.0             3h28m
99-master-iscsi-multipathing                                                                  2.2.0             5s
99-master-ssh                                                                                 3.2.0             3h33m
99-worker-generated-registries                     3b46a2229b706cc9aa53e3ed86a407fbe3c5dff4   3.2.0             3h28m
99-worker-ssh                                                                                 3.2.0             3h33m
rendered-master-31836288a429746662a2f4368a467543   3b46a2229b706cc9aa53e3ed86a407fbe3c5dff4   3.2.0             3h28m
rendered-worker-35bf278e01d5acee5966447683d5964f   3b46a2229b706cc9aa53e3ed86a407fbe3c5dff4   3.2.0             3h28m
<laptop-2>$
<laptop-2>$ oc get mcp 
NAME     CONFIG                                             UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
master   rendered-master-31836288a429746662a2f4368a467543   False     True       False      3              0                   0                     0                      3h29m
worker   rendered-worker-35bf278e01d5acee5966447683d5964f   True      False      False      2              2                   2                     0                      3h29m
<laptop-2>$ 
<laptop-2>$ oc get nodes
NAME                                         STATUS                     ROLES    AGE     VERSION
ip-10-0-148-134.us-west-2.compute.internal   Ready                      worker   3h23m   v1.21.1+6438632
ip-10-0-157-223.us-west-2.compute.internal   Ready                      master   3h30m   v1.21.1+6438632
ip-10-0-173-122.us-west-2.compute.internal   Ready,SchedulingDisabled   master   3h30m   v1.21.1+6438632
ip-10-0-177-190.us-west-2.compute.internal   Ready                      worker   3h23m   v1.21.1+6438632
ip-10-0-206-223.us-west-2.compute.internal   Ready                      master   3h30m   v1.21.1+6438632
<laptop-2>$ 
```

## Validate setup

Once the mc is rolled out and all masters have rebooted, let's check if we have now multipathing on the disk.

### Confirm mc is successfullt rolled out

```bash
<laptop-2>$ oc get mcp
NAME     CONFIG                                             UPDATED   UPDATING   DEGRADED   MACHINECOUNT   READYMACHINECOUNT   UPDATEDMACHINECOUNT   DEGRADEDMACHINECOUNT   AGE
master   rendered-master-3dcf6e2d8c97e44c15b8f8f2a2c9fc72   True      False      False      3              3                   3                     0                      3h50m
worker   rendered-worker-35bf278e01d5acee5966447683d5964f   True      False      False      2              2                   2                     0                      3h50m
<laptop-2>$ 
<laptop-2>$ oc get nodes
NAME                                         STATUS   ROLES    AGE     VERSION
ip-10-0-148-134.us-west-2.compute.internal   Ready    worker   3h43m   v1.21.1+6438632
ip-10-0-157-223.us-west-2.compute.internal   Ready    master   3h50m   v1.21.1+6438632
ip-10-0-173-122.us-west-2.compute.internal   Ready    master   3h51m   v1.21.1+6438632
ip-10-0-177-190.us-west-2.compute.internal   Ready    worker   3h44m   v1.21.1+6438632
ip-10-0-206-223.us-west-2.compute.internal   Ready    master   3h50m   v1.21.1+6438632
<laptop-2>$ 
```

### Check master nodes:

#### via oc debug

Doing ic via `oc debug node/<>` shows we do have mutipathing, however we're not seeing the path to use for the dis and `lsblk` is also not showing the disk is multipathed

```bash
<laptop-2>$ oc get no -l node-role.kubernetes.io/master --no-headers -o name | xargs -I {} -- oc debug {} -- bash -c 'chroot /host multipath -ll ; lsblk; ls -la /dev/mapper'
Starting pod/ip-10-0-157-223us-west-2computeinternal-debug ...
To use host binaries, run `chroot /host`
mpatha (36001405f79c4a247ee145bc8960b5a6c) dm-0 LIO-ORG,disk1
size=1.0T features='0' hwhandler='1 alua' wp=rw
|-+- policy='service-time 0' prio=50 status=active
| `- 1:0:0:1 sdb     8:16  active ready running
`-+- policy='service-time 0' prio=50 status=enabled
  `- 0:0:0:1 sda     8:0   active ready running
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda           8:0    0     1T  0 disk 
sdb           8:16   0     1T  0 disk 
nvme0n1     259:0    0   120G  0 disk 
|-nvme0n1p1 259:1    0     1M  0 part 
|-nvme0n1p2 259:2    0   127M  0 part 
|-nvme0n1p3 259:3    0   384M  0 part /host/boot
`-nvme0n1p4 259:4    0 119.5G  0 part /host/sysroot
total 0
drwxr-xr-x.  2 root root      60 Nov 21 14:57 .
drwxr-xr-x. 13 root root    2820 Nov 21 14:57 ..
crw-rw-rw-.  1 root root 10, 236 Nov 21 14:57 control

Removing debug pod ...
Starting pod/ip-10-0-173-122us-west-2computeinternal-debug ...
To use host binaries, run `chroot /host`
mpatha (3600140554654ebc71434a43a5dd19ae9) dm-0 LIO-ORG,disk2
size=1.0T features='0' hwhandler='1 alua' wp=rw
|-+- policy='service-time 0' prio=50 status=active
| `- 1:0:0:2 sdb     8:16  active ready running
`-+- policy='service-time 0' prio=50 status=enabled
  `- 0:0:0:2 sda     8:0   active ready running
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda           8:0    0     1T  0 disk 
sdb           8:16   0     1T  0 disk 
nvme0n1     259:0    0   120G  0 disk 
|-nvme0n1p1 259:1    0     1M  0 part 
|-nvme0n1p2 259:2    0   127M  0 part 
|-nvme0n1p3 259:3    0   384M  0 part /host/boot
`-nvme0n1p4 259:4    0 119.5G  0 part /host/sysroot
total 0
drwxr-xr-x.  2 root root      60 Nov 21 14:57 .
drwxr-xr-x. 13 root root    2820 Nov 21 14:57 ..
crw-rw-rw-.  1 root root 10, 236 Nov 21 14:57 control

Removing debug pod ...
Starting pod/ip-10-0-206-223us-west-2computeinternal-debug ...
To use host binaries, run `chroot /host`
mpatha (36001405dee83d2244a747939d1d59c4d) dm-0 LIO-ORG,disk0
size=1.0T features='0' hwhandler='1 alua' wp=rw
|-+- policy='service-time 0' prio=50 status=active
| `- 0:0:0:0 sdb     8:16  active ready running
`-+- policy='service-time 0' prio=50 status=enabled
  `- 1:0:0:0 sda     8:0   active ready running
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda           8:0    0     1T  0 disk 
sdb           8:16   0     1T  0 disk 
nvme0n1     259:0    0   120G  0 disk 
|-nvme0n1p1 259:1    0     1M  0 part 
|-nvme0n1p2 259:2    0   127M  0 part 
|-nvme0n1p3 259:3    0   384M  0 part /host/boot
`-nvme0n1p4 259:4    0 119.5G  0 part /host/sysroot
total 0
drwxr-xr-x.  2 root root      60 Nov 21 14:57 .
drwxr-xr-x. 13 root root    2820 Nov 21 14:57 ..
crw-rw-rw-.  1 root root 10, 236 Nov 21 14:57 control

Removing debug pod ...
<laptop-2>$ 
```

### via ssh login

Chck the same via `ssh` and `sudo`

#### Check Node IPs

```bash
<laptop-2>$ oc get nodes -o wide
NAME                                         STATUS   ROLES    AGE     VERSION           INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                                                       KERNEL-VERSION                 CONTAINER-RUNTIME
ip-10-0-148-134.us-west-2.compute.internal   Ready    worker   3h49m   v1.21.1+6438632   10.0.148.134   <none>        Red Hat Enterprise Linux CoreOS 48.84.202110270303-0 (Ootpa)   4.18.0-305.19.1.el8_4.x86_64   cri-o://1.21.3-8.rhaos4.8.git7415a53.el8
ip-10-0-157-223.us-west-2.compute.internal   Ready    master   3h56m   v1.21.1+6438632   10.0.157.223   <none>        Red Hat Enterprise Linux CoreOS 48.84.202110270303-0 (Ootpa)   4.18.0-305.19.1.el8_4.x86_64   cri-o://1.21.3-8.rhaos4.8.git7415a53.el8
ip-10-0-173-122.us-west-2.compute.internal   Ready    master   3h57m   v1.21.1+6438632   10.0.173.122   <none>        Red Hat Enterprise Linux CoreOS 48.84.202110270303-0 (Ootpa)   4.18.0-305.19.1.el8_4.x86_64   cri-o://1.21.3-8.rhaos4.8.git7415a53.el8
ip-10-0-177-190.us-west-2.compute.internal   Ready    worker   3h50m   v1.21.1+6438632   10.0.177.190   <none>        Red Hat Enterprise Linux CoreOS 48.84.202110270303-0 (Ootpa)   4.18.0-305.19.1.el8_4.x86_64   cri-o://1.21.3-8.rhaos4.8.git7415a53.el8
ip-10-0-206-223.us-west-2.compute.internal   Ready    master   3h57m   v1.21.1+6438632   10.0.206.223   <none>        Red Hat Enterprise Linux CoreOS 48.84.202110270303-0 (Ootpa)   4.18.0-305.19.1.el8_4.x86_64   cri-o://1.21.3-8.rhaos4.8.git7415a53.el8
<laptop-2>$ 
```

#### Check from jumphost

```bash
<laptop>$ ssh -i ~/.ssh/iscsi-demo.pem ec2-user@$PUB_DNS
Last login: Sun Nov 21 14:41:46 2021 from 149.14.88.26
[ec2-user@ip-10-0-0-47 ~]$ 
[ec2-user@ip-10-0-0-47 ~]$ 
[ec2-user@ip-10-0-0-47 ~]$ for IP in 10.0.157.223 10.0.173.122 10.0.206.223; do ssh -o StrictHostKeyChecking=no core@$IP "sudo multipath -ll;sudo lsblk; sudo ls -la /dev/mapper";echo "========";done
mpatha (36001405f79c4a247ee145bc8960b5a6c) dm-0 LIO-ORG,disk1
size=1.0T features='0' hwhandler='1 alua' wp=rw
|-+- policy='service-time 0' prio=50 status=active
| `- 1:0:0:1 sdb     8:16  active ready running
`-+- policy='service-time 0' prio=50 status=enabled
  `- 0:0:0:1 sda     8:0   active ready running
NAME        MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda           8:0    0     1T  0 disk  
`-mpatha    253:0    0     1T  0 mpath 
sdb           8:16   0     1T  0 disk  
`-mpatha    253:0    0     1T  0 mpath 
nvme0n1     259:0    0   120G  0 disk  
|-nvme0n1p1 259:1    0     1M  0 part  
|-nvme0n1p2 259:2    0   127M  0 part  
|-nvme0n1p3 259:3    0   384M  0 part  /boot
`-nvme0n1p4 259:4    0 119.5G  0 part  /sysroot
total 0
drwxr-xr-x.  2 root root      80 Nov 21 14:52 .
drwxr-xr-x. 17 root root    2980 Nov 21 14:52 ..
crw-------.  1 root root 10, 236 Nov 21 14:52 control
lrwxrwxrwx.  1 root root       7 Nov 21 14:52 mpatha -> ../dm-0
========
mpatha (3600140554654ebc71434a43a5dd19ae9) dm-0 LIO-ORG,disk2
size=1.0T features='0' hwhandler='1 alua' wp=rw
|-+- policy='service-time 0' prio=50 status=active
| `- 1:0:0:2 sdb     8:16  active ready running
`-+- policy='service-time 0' prio=50 status=enabled
  `- 0:0:0:2 sda     8:0   active ready running
NAME        MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda           8:0    0     1T  0 disk  
`-mpatha    253:0    0     1T  0 mpath 
sdb           8:16   0     1T  0 disk  
`-mpatha    253:0    0     1T  0 mpath 
nvme0n1     259:0    0   120G  0 disk  
|-nvme0n1p1 259:1    0     1M  0 part  
|-nvme0n1p2 259:2    0   127M  0 part  
|-nvme0n1p3 259:3    0   384M  0 part  /boot
`-nvme0n1p4 259:4    0 119.5G  0 part  /sysroot
total 0
drwxr-xr-x.  2 root root      80 Nov 21 14:38 .
drwxr-xr-x. 17 root root    2980 Nov 21 14:38 ..
crw-------.  1 root root 10, 236 Nov 21 14:38 control
lrwxrwxrwx.  1 root root       7 Nov 21 14:38 mpatha -> ../dm-0
========
mpatha (36001405dee83d2244a747939d1d59c4d) dm-0 LIO-ORG,disk0
size=1.0T features='0' hwhandler='1 alua' wp=rw
|-+- policy='service-time 0' prio=50 status=active
| `- 0:0:0:0 sdb     8:16  active ready running
`-+- policy='service-time 0' prio=50 status=enabled
  `- 1:0:0:0 sda     8:0   active ready running
NAME        MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda           8:0    0     1T  0 disk  
`-mpatha    253:0    0     1T  0 mpath 
sdb           8:16   0     1T  0 disk  
`-mpatha    253:0    0     1T  0 mpath 
nvme0n1     259:0    0   120G  0 disk  
|-nvme0n1p1 259:1    0     1M  0 part  
|-nvme0n1p2 259:2    0   127M  0 part  
|-nvme0n1p3 259:3    0   384M  0 part  /boot
`-nvme0n1p4 259:4    0 119.5G  0 part  /sysroot
total 0
drwxr-xr-x.  2 root root      80 Nov 21 14:45 .
drwxr-xr-x. 17 root root    2980 Nov 21 14:45 ..
crw-------.  1 root root 10, 236 Nov 21 14:45 control
lrwxrwxrwx.  1 root root       7 Nov 21 14:45 mpatha -> ../dm-0
========
[ec2-user@ip-10-0-0-47 ~]$ C
```

### Result

Here we can now see

* we have mutipath up and running
  
* ```
  mpatha (36001405dee83d2244a747939d1d59c4d) dm-0 LIO-ORG,disk0
  size=1.0T features='0' hwhandler='1 alua' wp=rw
  |-+- policy='service-time 0' prio=50 status=active
  | `- 0:0:0:0 sdb     8:16  active ready running
  `-+- policy='service-time 0' prio=50 status=enabled
    `- 1:0:0:0 sda     8:0   active ready running
  ```
  
* we see `mpath` in `lsblk` showing the disks
  
* ```bash
  NAME        MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
  sda           8:0    0     1T  0 disk  
  `-mpatha    253:0    0     1T  0 mpath 
  sdb           8:16   0     1T  0 disk  
  `-mpatha    253:0    0     1T  0 mpath 
  nvme0n1     259:0    0   120G  0 disk  
  [...]
  ```
  
* And we find the path `/dev/mapper/mpatha`
  
  This result we be used in the next step, after we have made [masters schedulable and labeled for ODF](Make_masters_schedulable_andlabel_for_ODF.md)
