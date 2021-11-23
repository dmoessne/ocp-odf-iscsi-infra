# Create iscsi target and map to hosts

Reference:
* [RHEL 8 Managing storage devices- Chapter 7. Configuring an iSCSI target](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_storage_devices/configuring-an-iscsi-target_managing-storage-devices)
* [RHEL 8 Managing storage devices- Chapter 8. Configuring an iSCSI initiator](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_storage_devices/configuring-an-iscsi-initiator_managing-storage-devices)

We will now check if we can reach the additional IPs on the iscsi instance, setup targetcli, verify we can login from the masters and ultimately create a machine config (mc) to start iscsi and multipathing which is then validates as a last step.

## Validate reachable IPs

From a second window we test if we can reach both additional IPs (`10.0.147.203` `10.0.147.46`) of the iscsi instance from master nodes so we can be sure the connection is as set by the security group.

```bash
<laptop-2>$ export KUBECONFIG=/home/dm/demo/cluster/auth/kubeconfig 
<laptop-2>$
<laptop-2>$ oc get no -l node-role.kubernetes.io/master --no-headers -o name | xargs -I {} -- oc debug {} -- bash -c 'ping -c1 10.0.147.203;ping -c1 10.0.147.46'
Starting pod/ip-10-0-157-223us-west-2computeinternal-debug ...
To use host binaries, run `chroot /host`
PING 10.0.147.203 (10.0.147.203) 56(84) bytes of data.
64 bytes from 10.0.147.203: icmp_seq=1 ttl=64 time=0.409 ms

--- 10.0.147.203 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.409/0.409/0.409/0.000 ms
PING 10.0.147.46 (10.0.147.46) 56(84) bytes of data.
64 bytes from 10.0.147.46: icmp_seq=1 ttl=64 time=0.336 ms

--- 10.0.147.46 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.336/0.336/0.336/0.000 ms

Removing debug pod ...
Starting pod/ip-10-0-173-122us-west-2computeinternal-debug ...
To use host binaries, run `chroot /host`
PING 10.0.147.203 (10.0.147.203) 56(84) bytes of data.
64 bytes from 10.0.147.203: icmp_seq=1 ttl=64 time=0.780 ms

--- 10.0.147.203 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.780/0.780/0.780/0.000 ms
PING 10.0.147.46 (10.0.147.46) 56(84) bytes of data.
64 bytes from 10.0.147.46: icmp_seq=1 ttl=64 time=0.686 ms

--- 10.0.147.46 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.686/0.686/0.686/0.000 ms

Removing debug pod ...
Starting pod/ip-10-0-206-223us-west-2computeinternal-debug ...
To use host binaries, run `chroot /host`
PING 10.0.147.203 (10.0.147.203) 56(84) bytes of data.
64 bytes from 10.0.147.203: icmp_seq=1 ttl=64 time=1.66 ms

--- 10.0.147.203 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.655/1.655/1.655/0.000 ms
PING 10.0.147.46 (10.0.147.46) 56(84) bytes of data.
64 bytes from 10.0.147.46: icmp_seq=1 ttl=64 time=0.907 ms

--- 10.0.147.46 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.907/0.907/0.907/0.000 ms

Removing debug pod ...
<laptop-2>$ 
```

## Get iscsi Initiators from masters

For setting up the iscsi target, we need the initiator names of the master nodes (which are there by default). We will later one configure a 1 disk to one master mapping:

```bash
laptop-2>$ oc get no -l node-role.kubernetes.io/master --no-headers -o name | xargs -I {} -- oc debug {} -- bash -c 'chroot /host cat /etc/iscsi/initiatorname.iscsi'
Starting pod/ip-10-0-157-223us-west-2computeinternal-debug ...
To use host binaries, run `chroot /host`
InitiatorName=iqn.1994-05.com.redhat:4d7babd662bf

Removing debug pod ...
Starting pod/ip-10-0-173-122us-west-2computeinternal-debug ...
To use host binaries, run `chroot /host`
InitiatorName=iqn.1994-05.com.redhat:63d48084613a

Removing debug pod ...
Starting pod/ip-10-0-206-223us-west-2computeinternal-debug ...
To use host binaries, run `chroot /host`
InitiatorName=iqn.1994-05.com.redhat:47cca1ac9480

Removing debug pod ...
<laptop-2>$
```

## Install targetcli on iscsi instance

Back to window one (still logged into iscsi instance) we deploy targetcli:

```bash
[ec2-user@ip-10-0-159-71 ~]$ sudo yum install -y targetcli 
Failed to set locale, defaulting to C.UTF-8
Updating Subscription Management repositories.
Unable to read consumer identity

This system is not registered to Red Hat Subscription Management. You can use subscription-manager to register.

Last metadata expiration check: 0:01:48 ago on Sun Nov 21 13:57:13 2021.
Dependencies resolved.
=====================================================================================================================================================================================================================
 Package                                               Architecture                             Version                                           Repository                                                    Size
=====================================================================================================================================================================================================================
Installing:
 targetcli                                             noarch                                   2.1.53-2.el8                                      rhel-8-appstream-rhui-rpms                                    80 k
Installing dependencies:
 python3-configshell                                   noarch                                   1:1.1.28-1.el8                                    rhel-8-baseos-rhui-rpms                                       72 k
 python3-kmod                                          x86_64                                   0.9-20.el8                                        rhel-8-baseos-rhui-rpms                                       90 k
 python3-rtslib                                        noarch                                   2.1.74-1.el8                                      rhel-8-baseos-rhui-rpms                                      103 k
 python3-urwid                                         x86_64                                   1.3.1-4.el8                                       rhel-8-baseos-rhui-rpms                                      783 k
 target-restore                                        noarch                                   2.1.74-1.el8                                      rhel-8-baseos-rhui-rpms                                       24 k

Transaction Summary
=====================================================================================================================================================================================================================
Install  6 Packages

Total download size: 1.1 M
Installed size: 4.2 M
Downloading Packages:
(1/6): python3-rtslib-2.1.74-1.el8.noarch.rpm                                                                                                                                        1.2 MB/s | 103 kB     00:00    
(2/6): targetcli-2.1.53-2.el8.noarch.rpm                                                                                                                                             844 kB/s |  80 kB     00:00    
(3/6): python3-urwid-1.3.1-4.el8.x86_64.rpm                                                                                                                                          7.3 MB/s | 783 kB     00:00    
(4/6): python3-configshell-1.1.28-1.el8.noarch.rpm                                                                                                                                   1.0 MB/s |  72 kB     00:00    
(5/6): target-restore-2.1.74-1.el8.noarch.rpm                                                                                                                                        302 kB/s |  24 kB     00:00    
(6/6): python3-kmod-0.9-20.el8.x86_64.rpm                                                                                                                                            1.3 MB/s |  90 kB     00:00    
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                5.3 MB/s | 1.1 MB     00:00     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                                                                             1/1 
  Installing       : python3-kmod-0.9-20.el8.x86_64                                                                                                                                                              1/6 
  Installing       : python3-rtslib-2.1.74-1.el8.noarch                                                                                                                                                          2/6 
  Installing       : target-restore-2.1.74-1.el8.noarch                                                                                                                                                          3/6 
  Running scriptlet: target-restore-2.1.74-1.el8.noarch                                                                                                                                                          3/6 
  Installing       : python3-urwid-1.3.1-4.el8.x86_64                                                                                                                                                            4/6 
  Installing       : python3-configshell-1:1.1.28-1.el8.noarch                                                                                                                                                   5/6 
  Installing       : targetcli-2.1.53-2.el8.noarch                                                                                                                                                               6/6 
  Running scriptlet: targetcli-2.1.53-2.el8.noarch                                                                                                                                                               6/6 
  Verifying        : targetcli-2.1.53-2.el8.noarch                                                                                                                                                               1/6 
  Verifying        : python3-urwid-1.3.1-4.el8.x86_64                                                                                                                                                            2/6 
  Verifying        : python3-rtslib-2.1.74-1.el8.noarch                                                                                                                                                          3/6 
  Verifying        : python3-configshell-1:1.1.28-1.el8.noarch                                                                                                                                                   4/6 
  Verifying        : target-restore-2.1.74-1.el8.noarch                                                                                                                                                          5/6 
  Verifying        : python3-kmod-0.9-20.el8.x86_64                                                                                                                                                              6/6 
Installed products updated.

Installed:
  python3-configshell-1:1.1.28-1.el8.noarch  python3-kmod-0.9-20.el8.x86_64  python3-rtslib-2.1.74-1.el8.noarch  python3-urwid-1.3.1-4.el8.x86_64  target-restore-2.1.74-1.el8.noarch  targetcli-2.1.53-2.el8.noarch 

Complete!
[ec2-user@ip-10-0-159-71 ~]$ 
```

## Check additional volumes

For the next step (setting up targetcli) we also should verify the disk names of the mapped volumes:

```bash
[ec2-user@ip-10-0-159-71 ~]$ lsblk
NAME    MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
xvda    202:0    0  10G  0 disk 
|-xvda1 202:1    0   1M  0 part 
`-xvda2 202:2    0  10G  0 part /
xvde    202:64   0   1T  0 disk 
xvdf    202:80   0   1T  0 disk 
xvdg    202:96   0   1T  0 disk 
[ec2-user@ip-10-0-159-71 ~]$ 
[ec2-user@ip-10-0-159-71 ~]$ 
```

## Create targets

We will map every disk exclusively to one of the master nodes

```bash
[ec2-user@ip-10-0-159-71 ~]$ sudo targetcli
targetcli shell version 2.1.53
Copyright 2011-2013 by Datera, Inc and others.
For help on commands, type 'help'.
/>
/> cd /backstores/block/
/backstores/block> create disk0 /dev/xvde
Created block storage object disk0 using /dev/xvde.
/backstores/block> create disk1 /dev/xvdf
Created block storage object disk1 using /dev/xvdf.
/backstores/block> create disk2 /dev/xvdg
Created block storage object disk2 using /dev/xvdg.
/backstores/block> 
/backstores/block> 
/backstores/block> cd /iscsi
/iscsi> create
Created target iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb.
Created TPG 1.
Global pref auto_add_default_portal=true
Created default portal listening on all IPs (0.0.0.0), port 3260.
/iscsi> 
/iscsi> ls
o- iscsi .............................................................................................................. [Targets: 1]
  o- iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb .................................................... [TPGs: 1]
    o- tpg1 ................................................................................................. [no-gen-acls, no-auth]
      o- acls ............................................................................................................ [ACLs: 0]
      o- luns ............................................................................................................ [LUNs: 0]
      o- portals ...................................................................................................... [Portals: 1]
        o- 0.0.0.0:3260 ....................................................................................................... [OK]
/iscsi> 
/iscsi> cd iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb/tpg1/acls 
/iscsi/iqn.20...6eb/tpg1/acls> 
/iscsi/iqn.20...6eb/tpg1/acls> create iqn.1994-05.com.redhat:4d7babd662bf
Created Node ACL for iqn.1994-05.com.redhat:4d7babd662bf
/iscsi/iqn.20...6eb/tpg1/acls> create iqn.1994-05.com.redhat:63d48084613a
Created Node ACL for iqn.1994-05.com.redhat:63d48084613a
/iscsi/iqn.20...6eb/tpg1/acls> create iqn.1994-05.com.redhat:47cca1ac9480
Created Node ACL for iqn.1994-05.com.redhat:47cca1ac9480
/iscsi/iqn.20...6eb/tpg1/acls> 
/iscsi/iqn.20...6eb/tpg1/acls> cd /iscsi/iqn.2003-01.org.linux-iscsi.ip-10-0-159-71.x8664:sn.89a63235e6eb/tpg1/portals/
/iscsi/iqn.20.../tpg1/portals> ls
o- portals ............................................................................................................ [Portals: 1]
  o- 0.0.0.0:3260 ............................................................................................................. [OK]
/iscsi/iqn.20.../tpg1/portals> cd ../luns 
/iscsi/iqn.20...6eb/tpg1/luns> create /backstores/block/disk0 lun0
Created LUN 0.
Created LUN 0->0 mapping in node ACL iqn.1994-05.com.redhat:47cca1ac9480
Created LUN 0->0 mapping in node ACL iqn.1994-05.com.redhat:63d48084613a
Created LUN 0->0 mapping in node ACL iqn.1994-05.com.redhat:4d7babd662bf
/iscsi/iqn.20...6eb/tpg1/luns> create /backstores/block/disk1 lun1
Created LUN 1.
Created LUN 1->1 mapping in node ACL iqn.1994-05.com.redhat:47cca1ac9480
Created LUN 1->1 mapping in node ACL iqn.1994-05.com.redhat:63d48084613a
Created LUN 1->1 mapping in node ACL iqn.1994-05.com.redhat:4d7babd662bf
/iscsi/iqn.20...6eb/tpg1/luns> create /backstores/block/disk2 lun2
Created LUN 2.
Created LUN 2->2 mapping in node ACL iqn.1994-05.com.redhat:47cca1ac9480
Created LUN 2->2 mapping in node ACL iqn.1994-05.com.redhat:63d48084613a
Created LUN 2->2 mapping in node ACL iqn.1994-05.com.redhat:4d7babd662bf
/iscsi/iqn.20...6eb/tpg1/luns> 
/iscsi/iqn.20...6eb/tpg1/luns> cd ..
/iscsi/iqn.20...3235e6eb/tpg1> ls
o- tpg1 ..................................................................................................... [no-gen-acls, no-auth]
  o- acls ................................................................................................................ [ACLs: 3]
  | o- iqn.1994-05.com.redhat:47cca1ac9480 ........................................................................ [Mapped LUNs: 3]
  | | o- mapped_lun0 ....................................................................................... [lun0 block/disk0 (rw)]
  | | o- mapped_lun1 ....................................................................................... [lun1 block/disk1 (rw)]
  | | o- mapped_lun2 ....................................................................................... [lun2 block/disk2 (rw)]
  | o- iqn.1994-05.com.redhat:4d7babd662bf ........................................................................ [Mapped LUNs: 3]
  | | o- mapped_lun0 ....................................................................................... [lun0 block/disk0 (rw)]
  | | o- mapped_lun1 ....................................................................................... [lun1 block/disk1 (rw)]
  | | o- mapped_lun2 ....................................................................................... [lun2 block/disk2 (rw)]
  | o- iqn.1994-05.com.redhat:63d48084613a ........................................................................ [Mapped LUNs: 3]
  |   o- mapped_lun0 ....................................................................................... [lun0 block/disk0 (rw)]
  |   o- mapped_lun1 ....................................................................................... [lun1 block/disk1 (rw)]
  |   o- mapped_lun2 ....................................................................................... [lun2 block/disk2 (rw)]
  o- luns ................................................................................................................ [LUNs: 3]
  | o- lun0 ........................................................................... [block/disk0 (/dev/xvde) (default_tg_pt_gp)]
  | o- lun1 ........................................................................... [block/disk1 (/dev/xvdf) (default_tg_pt_gp)]
  | o- lun2 ........................................................................... [block/disk2 (/dev/xvdg) (default_tg_pt_gp)]
  o- portals .......................................................................................................... [Portals: 1]
    o- 0.0.0.0:3260 ........................................................................................................... [OK]
/iscsi/iqn.20...3235e6eb/tpg1> cd acls/iqn.1994-05.com.redhat:47cca1ac9480/
/iscsi/iqn.20...:47cca1ac9480> ls
o- iqn.1994-05.com.redhat:47cca1ac9480 ............................................................................ [Mapped LUNs: 3]
  o- mapped_lun0 ........................................................................................... [lun0 block/disk0 (rw)]
  o- mapped_lun1 ........................................................................................... [lun1 block/disk1 (rw)]
  o- mapped_lun2 ........................................................................................... [lun2 block/disk2 (rw)]
/iscsi/iqn.20...:47cca1ac9480> delete 1
Deleted Mapped LUN 1.
/iscsi/iqn.20...:47cca1ac9480> delete 2
Deleted Mapped LUN 2.
/iscsi/iqn.20...:47cca1ac9480> cd ../iqn.1994-05.com.redhat:4d7babd662bf/
/iscsi/iqn.20...:4d7babd662bf> delete 0
Deleted Mapped LUN 0.
/iscsi/iqn.20...:4d7babd662bf> delete 2
Deleted Mapped LUN 2.
/iscsi/iqn.20...:4d7babd662bf> cd ../iqn.1994-05.com.redhat:63d48084613a
/iscsi/iqn.20...:63d48084613a> delete 0
Deleted Mapped LUN 0.
/iscsi/iqn.20...:63d48084613a> delete 1
Deleted Mapped LUN 1.
/iscsi/iqn.20...:63d48084613a> cd ..
/iscsi/iqn.20...6eb/tpg1/acls> ls
o- acls .................................................................................................................. [ACLs: 3]
  o- iqn.1994-05.com.redhat:47cca1ac9480 .......................................................................... [Mapped LUNs: 1]
  | o- mapped_lun0 ......................................................................................... [lun0 block/disk0 (rw)]
  o- iqn.1994-05.com.redhat:4d7babd662bf .......................................................................... [Mapped LUNs: 1]
  | o- mapped_lun1 ......................................................................................... [lun1 block/disk1 (rw)]
  o- iqn.1994-05.com.redhat:63d48084613a .......................................................................... [Mapped LUNs: 1]
    o- mapped_lun2 ......................................................................................... [lun2 block/disk2 (rw)]
/iscsi/iqn.20...6eb/tpg1/acls> 
/iscsi/iqn.20...6eb/tpg1/acls> cd /
/> saveconfig
Last 10 configs saved in /etc/target/backup/.
Configuration saved to /etc/target/saveconfig.json
/> 
```

With the targets created, let's [login from the nodes (masters) and automate iscsi login on reboot](Login_to_target_and_automate_this_via_mc.md)
