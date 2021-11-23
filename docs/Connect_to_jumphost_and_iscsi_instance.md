# Connect to jumphost and_iscsi instance

To connect to the jumphost, we need

* the Public IP
  
  * ```export PUB_DNS=`aws ec2 describe-instances --filters "Name=tag:Name,Values=iscsi-demo-bastion" --query "Reservations[*].Instances[*].PublicDnsName" --output=text```
* and the key we have used (iscsi-demo.pem)
  

## check jumphost login

```bash
<laptop>$ ssh -i ~/.ssh/iscsi-demo.pem ec2-user@$PUB_DNS
The authenticity of host 'ec2-34-217-20-131.us-west-2.compute.amazonaws.com (34.217.20.131)' can't be established.
ECDSA key fingerprint is SHA256:IABWWB92czAq1bO7DI6/O3uIgEJ8ELeumWQovslN1zU.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'ec2-34-217-20-131.us-west-2.compute.amazonaws.com,34.217.20.131' (ECDSA) to the list of known hosts.
[ec2-user@ip-10-0-0-47 ~]$ logout
Connection to ec2-34-217-20-131.us-west-2.compute.amazonaws.com closed.
<laptop>$ 
```

### Copy key

```bash
<laptop>$ scp -i ~/.ssh/iscsi-demo.pem  ~/.ssh/iscsi-demo.pem ec2-user@$PUB_DNS:
iscsidemo.pem                                              100% 1674     9.0KB/s   00:00
<laptop>$
```

## ssh to iscsi host

Get iscsi instance IPs (again)

```bash
<laptop>$ aws ec2 describe-instances --filters "Name=tag:Name,Values=iscsi-demo-int" --query "Reservations[*].Instances[*].NetworkInterfaces[*].PrivateIpAddresses" --output=text
True    ip-10-0-159-71.us-west-2.compute.internal       10.0.159.71
False   ip-10-0-147-203.us-west-2.compute.internal      10.0.147.203
False   ip-10-0-147-46.us-west-2.compute.internal       10.0.147.46
<laptop>$ 
```

```bash
<laptop>$ ssh -i ~/.ssh/iscsi-demo.pem ec2-user@$PUB_DNS
Last login: Sun Nov 21 15:03:55 2021 from 149.14.88.26
[ec2-user@ip-10-0-0-47 ~]$ 
[ec2-user@ip-10-0-0-47 ~]$ ls -la iscsi-demo.pem 
-rw-------. 1 ec2-user ec2-user 1674 Nov 21 13:24 iscsi-demo.pem
[ec2-user@ip-10-0-0-47 ~]$ 
[ec2-user@ip-10-0-0-47 ~]$ ssh -i iscsi-demo.pem 10.0.159.71
The authenticity of host '10.0.159.71 (10.0.159.71)' can't be established.
ECDSA key fingerprint is SHA256:64QhPJ3QeOcdJH7wTa85LyM26Myu3Sq6xsdmoQj2SyI.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.0.159.71' (ECDSA) to the list of known hosts.
[ec2-user@ip-10-0-159-71 ~]$ 
[ec2-user@ip-10-0-159-71 ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9001 qdisc mq state UP group default qlen 1000
    link/ether 06:08:b9:b9:6d:93 brd ff:ff:ff:ff:ff:ff
    inet 10.0.159.71/19 brd 10.0.159.255 scope global noprefixroute eth0
       valid_lft forever preferred_lft forever
    inet 10.0.147.203/19 brd 10.0.159.255 scope global secondary noprefixroute eth0
       valid_lft forever preferred_lft forever
    inet 10.0.147.46/19 brd 10.0.159.255 scope global secondary noprefixroute eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::408:b9ff:feb9:6d93/64 scope link 
       valid_lft forever preferred_lft forever
[ec2-user@ip-10-0-159-71 ~]$ 
```

Now we are ready to [create the iscsi target and map them to the hosts](Create_iscsi_target_and_map_to_hosts.md)
