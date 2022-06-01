# set up bastion and iscsi host

Reference:
* [AWS CLI Command Reference ec2](https://docs.aws.amazon.com/cli/latest/reference/ec2/index.html)

In this section we will create 2 hosts in the automatically created VPC :

1. bastion host, so we can login directly via ssh to OCP nodes and the to be created iscsi host
2. iscsi host, located in private subnet and having additional IPs and volumes for demoing multipathing via iscsi:

Before deploying those 2 hosts, we need to get some information about the created VPC, create 2 security groups to allow ssh to jumphost and all traffic to the iscsi host

## Get VPC details

In order to create our security groups and also create the hosts later on, we need the VPC id as well as the subnet ids of at least the private and public subnet in one availability zone (we have choosen us-west-2a here). Those values are exported to make further usage more convenient:

```bash
<laptop>$ export VPC=`aws ec2 describe-vpcs --filters "Name=tag-key,Values=project" |jq .Vpcs[].VpcId |sed 's/"//g'`
<laptop>$ 
<laptop>$ echo $VPC
vpc-02464a603021381f4
<laptop>$ 
<laptop>$ aws ec2 describe-subnets --filter Name=vpc-id,Values=$VPC | jq -r '.Subnets[]|.SubnetId+" "+.CidrBlock+" "+(.Tags[]|select(.Key=="Name").Value)' |grep west-2a
subnet-0836f9be3af8a48e8 10.0.0.0/19 iscsi-demo-lrl9s-public-us-west-2a
subnet-0d3000da9907a2c28 10.0.128.0/19 iscsi-demo-lrl9s-private-us-west-2a
<laptop>$ 
<laptop>$ export NET_PUB=subnet-0836f9be3af8a48e8
<laptop>$ export NET_PRIV=subnet-0d3000da9907a2c28
<laptop>$ 
```

## Create Security Groups (SG)

### Public SG (jumphost)

The Public security group will allow ssh traffic from everywhere as well as all other traffic from ```10.0.0.0/16``` which is the VPCs newtork

```bash
<laptop>$ aws ec2 create-security-group --description iscsi-demo-public-sg --group-name iscsi-demo-public-sg --vpc-id $VPC
{
    "GroupId": "sg-05693c54c8161d133"
}
<laptop>$ 
<laptop>$ export SG_PUB=sg-05693c54c8161d133
<laptop>$ 
<laptop>$ aws ec2 authorize-security-group-ingress --group-id  $SG_PUB --protocol tcp --port 22 --cidr 0.0.0.0/0
<laptop>$ aws ec2 authorize-security-group-ingress --group-id  $SG_PUB --protocol all --cidr 10.0.0.0/16
<laptop>$ aws ec2 create-tags --resources $SG_PUB --tags Key=Name,Value=iscsi-demo-public-sg
<laptop>$ aws ec2 describe-security-groups --group-id $SG_PUB
{
    "SecurityGroups": [
        {
            "Description": "iscsi-demo-public-sg",
            "GroupName": "iscsi-demo-public-sg",
            "IpPermissions": [
                {
                    "IpProtocol": "-1",
                    "IpRanges": [
                        {
                            "CidrIp": "10.0.0.0/16"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "UserIdGroupPairs": []
                },
                {
                    "FromPort": 22,
                    "IpProtocol": "tcp",
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "ToPort": 22,
                    "UserIdGroupPairs": []
                }
            ],
            "OwnerId": "015719942846",
            "GroupId": "sg-05693c54c8161d133",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "-1",
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "UserIdGroupPairs": []
                }
            ],
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "iscsi-demo-public-sg"
                }
            ],
            "VpcId": "vpc-02464a603021381f4"
        }
    ]
}
<laptop>$ 
```

### Priva SG (iscsi)

Private SG will allow all traffic inside ```10.0.0.0/16``` (as well as implicitly egress external access , i.e. all traffic going out to reach e.g. AWS update servers)

```bash
<laptop>$ aws ec2 create-security-group --description iscsi-demo-private-sg --group-name iscsi-demo-private-sg --vpc-id $VPC
{
    "GroupId": "sg-0684d95bb0195b72d"
}
<laptop>$
<laptop>$ export SG_PRIV=sg-0684d95bb0195b72d
<laptop>$
<laptop>$ aws ec2 create-tags --resources $SG_PRIV --tags Key=Name,Value=dmoessne2-sg-private
<laptop>$ aws ec2 authorize-security-group-ingress --group-id $SG_PRIV  --protocol all  --cidr 10.0.0.0/16
<laptop>$ aws ec2 authorize-security-group-egress  --group-id  $SG_PRIV --protocol all  --cidr 10.0.0.0/16
<laptop>$ 
<laptop>$ aws ec2 describe-security-groups --group-id $SG_PRIV
{
    "SecurityGroups": [
        {
            "Description": "iscsi-demo-private-sg",
            "GroupName": "iscsi-demo-private-sg",
            "IpPermissions": [
                {
                    "IpProtocol": "-1",
                    "IpRanges": [
                        {
                            "CidrIp": "10.0.0.0/16"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "UserIdGroupPairs": []
                }
            ],
            "OwnerId": "015719942846",
            "GroupId": "sg-0684d95bb0195b72d",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "-1",
                    "IpRanges": [
                        {
                            "CidrIp": "10.0.0.0/16"
                        },
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "UserIdGroupPairs": []
                }
            ],
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "dmoessne2-sg-private"
                }
            ],
            "VpcId": "vpc-02464a603021381f4"
        }
    ]
}
<laptop>$ 
```

## bastion / jumphost

Now, that security groups are created, we can create the jumphost.

First, we need a valid AMI in this AWS region:

```bash
<laptop>$ aws ec2 describe-images --query 'sort_by(Images, &CreationDate)[*].[CreationDate,Name,ImageId]' --filters "Name=name,Values=RHEL_HA-8.4.0_HVM-*" --region us-west-2 --output table
----------------------------------------------------------------------------------------------------------
|                                             DescribeImages                                             |
+---------------------------+---------------------------------------------------+------------------------+
|  2021-05-18T19:01:21.000Z |  RHEL_HA-8.4.0_HVM-20210504-x86_64-2-Hourly2-GP2  |  ami-0b28dfc7adc325ef4 |
+---------------------------+---------------------------------------------------+------------------------+
<laptop>$ 
<laptop>$ export AMI=ami-0b28dfc7adc325ef4
```

And now we can create the jumphost with a public IP and tag it accordingly

```bash
<laptop>$ aws ec2 run-instances --image-id $AMI --count 1 --instance-type  t2.medium --key-name iscsi-demo --security-group-ids $SG_PUB --subnet-id $NET_PUB  --associate-public-ip-address
{
    "Groups": [],
    "Instances": [
        {
            "AmiLaunchIndex": 0,
            "ImageId": "ami-0b28dfc7adc325ef4",
            "InstanceId": "i-0937021bddbf5cb5c",
            "InstanceType": "t2.medium",
            "KeyName": "iscsi-demo",
            "LaunchTime": "2021-11-21T12:28:19+00:00",
            "Monitoring": {
                "State": "disabled"
            },
            "Placement": {
                "AvailabilityZone": "us-west-2a",
                "GroupName": "",
                "Tenancy": "default"
            },
            "PrivateDnsName": "ip-10-0-0-47.us-west-2.compute.internal",
            "PrivateIpAddress": "10.0.0.47",
            "ProductCodes": [],
            "PublicDnsName": "",
            "State": {
                "Code": 0,
                "Name": "pending"
            },
            "StateTransitionReason": "",
            "SubnetId": "subnet-0836f9be3af8a48e8",
            "VpcId": "vpc-02464a603021381f4",
            "Architecture": "x86_64",
            "BlockDeviceMappings": [],
            "ClientToken": "c80d8656-df75-41f4-9f9e-837700624d19",
            "EbsOptimized": false,
            "EnaSupport": true,
            "Hypervisor": "xen",
            "NetworkInterfaces": [
                {
                    "Attachment": {
                        "AttachTime": "2021-11-21T12:28:19+00:00",
                        "AttachmentId": "eni-attach-0559b37f453c15756",
                        "DeleteOnTermination": true,
                        "DeviceIndex": 0,
                        "Status": "attaching",
                        "NetworkCardIndex": 0
                    },
                    "Description": "",
                    "Groups": [
                        {
                            "GroupName": "iscsi-demo-public-sg",
                            "GroupId": "sg-05693c54c8161d133"
                        }
                    ],
                    "Ipv6Addresses": [],
                    "MacAddress": "06:50:19:33:f8:f3",
                    "NetworkInterfaceId": "eni-0ed193c7d0c766d55",
                    "OwnerId": "015719942846",
                    "PrivateDnsName": "ip-10-0-0-47.us-west-2.compute.internal",
                    "PrivateIpAddress": "10.0.0.47",
                    "PrivateIpAddresses": [
                        {
                            "Primary": true,
                            "PrivateDnsName": "ip-10-0-0-47.us-west-2.compute.internal",
                            "PrivateIpAddress": "10.0.0.47"
                        }
                    ],
                    "SourceDestCheck": true,
                    "Status": "in-use",
                    "SubnetId": "subnet-0836f9be3af8a48e8",
                    "VpcId": "vpc-02464a603021381f4",
                    "InterfaceType": "interface"
                }
            ],
            "RootDeviceName": "/dev/sda1",
            "RootDeviceType": "ebs",
            "SecurityGroups": [
                {
                    "GroupName": "iscsi-demo-public-sg",
                    "GroupId": "sg-05693c54c8161d133"
                }
            ],
            "SourceDestCheck": true,
            "StateReason": {
                "Code": "pending",
                "Message": "pending"
            },
            "VirtualizationType": "hvm",
            "CpuOptions": {
                "CoreCount": 2,
                "ThreadsPerCore": 1
            },
            "CapacityReservationSpecification": {
                "CapacityReservationPreference": "open"
            },
            "MetadataOptions": {
                "State": "pending",
                "HttpTokens": "optional",
                "HttpPutResponseHopLimit": 1,
                "HttpEndpoint": "enabled"
            },
            "EnclaveOptions": {
                "Enabled": false
            }
        }
    ],
    "OwnerId": "015719942846",
    "ReservationId": "r-02c7d96fdd58dbe26"
}
<laptop>$ 
<laptop>$ aws ec2 create-tags --tags Key=Name,Value=iscsi-demo-bastion --resources i-0937021bddbf5cb5c
<laptop>$
```

Finally we need the external DNS name which we export, so we can later on ssh to it with our key:

```bash
<laptop>$  aws ec2 describe-instances --filters "Name=tag:Name,Values=iscsi-demo-bastion" --query "Reservations[*].Instances[*].PublicDnsName" --output=text
ec2-34-217-20-131.us-west-2.compute.amazonaws.com
<laptop>$ 
<laptop>$ export PUB_DNS=`aws ec2 describe-instances --filters "Name=tag:Name,Values=iscsi-demo-bastion" --query "Reservations[*].Instances[*].PublicDnsName" --output=text`
<laptop>$ 
```

## iscsi host

The iscsi host will be just available internally (no external IP), only via our previously create jump host. It will have 2 additional IPs to *demonstrate* multipathing.

We also will attach 3 1TiB Disks which will then be shared via iscsi (targetcli) to the nodes (masters in our case)

### create host

Create this host with the same AMI and tag it accordingly, export the instance ID (for attaching volumes later on). Also, we will check the IPs added so we can later on connect

```bash
<laptop>$ aws ec2 run-instances --image-id $AMI --count 1 --instance-type  t2.medium --key-name iscsi-demo --security-group-ids $SG_PRIV --subnet-id $NET_PRIV --secondary-private-ip-address-count 2 --no-associate-public-ip-address
{
    "Groups": [],
    "Instances": [
        {
            "AmiLaunchIndex": 0,
            "ImageId": "ami-0b28dfc7adc325ef4",
            "InstanceId": "i-0dadf4bd0b2480313",
            "InstanceType": "t2.medium",
            "KeyName": "iscsi-demo",
            "LaunchTime": "2021-11-21T13:12:32+00:00",
            "Monitoring": {
                "State": "disabled"
            },
            "Placement": {
                "AvailabilityZone": "us-west-2a",
                "GroupName": "",
                "Tenancy": "default"
            },
            "PrivateDnsName": "ip-10-0-159-71.us-west-2.compute.internal",
            "PrivateIpAddress": "10.0.159.71",
            "ProductCodes": [],
            "PublicDnsName": "",
            "State": {
                "Code": 0,
                "Name": "pending"
            },
            "StateTransitionReason": "",
            "SubnetId": "subnet-0d3000da9907a2c28",
            "VpcId": "vpc-02464a603021381f4",
            "Architecture": "x86_64",
            "BlockDeviceMappings": [],
            "ClientToken": "aef7025d-a004-4ad5-bb6e-fb99427ef9d2",
            "EbsOptimized": false,
            "EnaSupport": true,
            "Hypervisor": "xen",
            "NetworkInterfaces": [
                {
                    "Attachment": {
                        "AttachTime": "2021-11-21T13:12:32+00:00",
                        "AttachmentId": "eni-attach-0b7d2f17405c95b61",
                        "DeleteOnTermination": true,
                        "DeviceIndex": 0,
                        "Status": "attaching",
                        "NetworkCardIndex": 0
                    },
                    "Description": "",
                    "Groups": [
                        {
                            "GroupName": "iscsi-demo-private-sg",
                            "GroupId": "sg-0684d95bb0195b72d"
                        }
                    ],
                    "Ipv6Addresses": [],
                    "MacAddress": "06:08:b9:b9:6d:93",
                    "NetworkInterfaceId": "eni-0bf6432671744273f",
                    "OwnerId": "015719942846",
                    "PrivateDnsName": "ip-10-0-159-71.us-west-2.compute.internal",
                    "PrivateIpAddress": "10.0.159.71",
                    "PrivateIpAddresses": [
                        {
                            "Primary": true,
                            "PrivateDnsName": "ip-10-0-159-71.us-west-2.compute.internal",
                            "PrivateIpAddress": "10.0.159.71"
                        },
                        {
                            "Primary": false,
                            "PrivateDnsName": "ip-10-0-147-203.us-west-2.compute.internal",
                            "PrivateIpAddress": "10.0.147.203"
                        },
                        {
                            "Primary": false,
                            "PrivateDnsName": "ip-10-0-147-46.us-west-2.compute.internal",
                            "PrivateIpAddress": "10.0.147.46"
                        }
                    ],
                    "SourceDestCheck": true,
                    "Status": "in-use",
                    "SubnetId": "subnet-0d3000da9907a2c28",
                    "VpcId": "vpc-02464a603021381f4",
                    "InterfaceType": "interface"
                }
            ],
            "RootDeviceName": "/dev/sda1",
            "RootDeviceType": "ebs",
            "SecurityGroups": [
                {
                    "GroupName": "iscsi-demo-private-sg",
                    "GroupId": "sg-0684d95bb0195b72d"
                }
            ],
            "SourceDestCheck": true,
            "StateReason": {
                "Code": "pending",
                "Message": "pending"
            },
            "VirtualizationType": "hvm",
            "CpuOptions": {
                "CoreCount": 2,
                "ThreadsPerCore": 1
            },
            "CapacityReservationSpecification": {
                "CapacityReservationPreference": "open"
            },
            "MetadataOptions": {
                "State": "pending",
                "HttpTokens": "optional",
                "HttpPutResponseHopLimit": 1,
                "HttpEndpoint": "enabled"
            },
            "EnclaveOptions": {
                "Enabled": false
            }
        }
    ],
    "OwnerId": "015719942846",
    "ReservationId": "r-0bbe4ce2bb8cf9328"
}
<laptop>$ 
<laptop>$ aws ec2 create-tags --tags Key=Name,Value=iscsi-demo-int --resources i-0dadf4bd0b2480313
<laptop>$ <laptop>$ export ISCI_EC2=i-0dadf4bd0b2480313
<laptop>$ 
<laptop>$ aws ec2 describe-instances --filters "Name=tag:Name,Values=iscsi-demo-int" --query "Reservations[*].Instances[*].NetworkInterfaces[*].PrivateIpAddresses" --output=text 
True    ip-10-0-159-71.us-west-2.compute.internal       10.0.159.71
False   ip-10-0-147-203.us-west-2.compute.internal      10.0.147.203
False   ip-10-0-147-46.us-west-2.compute.internal       10.0.147.46
<laptop>$ 
```

### create and attach volume

As a last setp we create and attach volumes to the iscsi instance which will later on be used as iscsi targets:

```
<laptop>$ aws ec2 create-volume --availability-zone us-west-2a --volume-type gp2 --size 1024
{
    "AvailabilityZone": "us-west-2a",
    "CreateTime": "2021-11-21T13:19:32+00:00",
    "Encrypted": false,
    "Size": 1024,
    "SnapshotId": "",
    "State": "creating",
    "VolumeId": "vol-067c355b2247b16ec",
    "Iops": 3072,
    "Tags": [],
    "VolumeType": "gp2",
    "MultiAttachEnabled": false
}
<laptop>$ aws ec2 create-tags --tags Key=Name,Value=iscsi-demo-bastion --resources vol-067c355b2247b16ec
<laptop>$ aws ec2 attach-volume --device xvde --instance-id $ISCI_EC2  --volume-id vol-067c355b2247b16ec
{
    "AttachTime": "2021-11-21T13:20:30.977000+00:00",
    "Device": "xvde",
    "InstanceId": "i-0dadf4bd0b2480313",
    "State": "attaching",
    "VolumeId": "vol-067c355b2247b16ec"
}
<laptop>$ 
<laptop>$ 
<laptop>$ aws ec2 create-volume --availability-zone us-west-2a --volume-type gp2 --size 1024
{
    "AvailabilityZone": "us-west-2a",
    "CreateTime": "2021-11-21T13:20:40+00:00",
    "Encrypted": false,
    "Size": 1024,
    "SnapshotId": "",
    "State": "creating",
    "VolumeId": "vol-0fa86839abdd4c6f0",
    "Iops": 3072,
    "Tags": [],
    "VolumeType": "gp2",
    "MultiAttachEnabled": false
}
<laptop>$ aws ec2 create-tags --tags Key=Name,Value=iscsi-demo-bastion --resources vol-0fa86839abdd4c6f0
<laptop>$ aws ec2 attach-volume --device xvdf --instance-id $ISCI_EC2  --volume-id vol-0fa86839abdd4c6f0
{
    "AttachTime": "2021-11-21T13:20:51.838000+00:00",
    "Device": "xvdf",
    "InstanceId": "i-0dadf4bd0b2480313",
    "State": "attaching",
    "VolumeId": "vol-0fa86839abdd4c6f0"
}
<laptop>$ 
<laptop>$ aws ec2 create-volume --availability-zone us-west-2a --volume-type gp2 --size 1024
{
    "AvailabilityZone": "us-west-2a",
    "CreateTime": "2021-11-21T13:20:58+00:00",
    "Encrypted": false,
    "Size": 1024,
    "SnapshotId": "",
    "State": "creating",
    "VolumeId": "vol-082832c05b71c10ff",
    "Iops": 3072,
    "Tags": [],
    "VolumeType": "gp2",
    "MultiAttachEnabled": false
}
<laptop>$ aws ec2 create-tags --tags Key=Name,Value=iscsi-demo-bastion --resources vol-082832c05b71c10ff
<laptop>$ aws ec2 attach-volume --device xvdg --instance-id $ISCI_EC2 --volume-id vol-082832c05b71c10ff
{
    "AttachTime": "2021-11-21T13:21:19.238000+00:00",
    "Device": "xvdg",
    "InstanceId": "i-0dadf4bd0b2480313",
    "State": "attaching",
    "VolumeId": "vol-082832c05b71c10ff"
```

After the hosts are set up we will [connect to them](Connect_to_jumphost_and_iscsi_instance.md)
