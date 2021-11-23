# ocp-odf-iscsi-infra

**<mark>Work in progress</mark>**

Missing is:

* doc references
* sanity checks
* consmetic things
* review

-------------------------------------------------------------

Purpose: 

Goal of this documentation is to show how to deploy a OCP 4.8 cluster with ODF 4.8 as follows

* based on AWS though this should be doable on any other platform (3 big masters - m5.12xlarge - to deploy ODF on top of it and 2 workers reserved for custom workload)
* Provide multipathed iscsi for backing Local Storage Operator (LSO) and deploy Openshift Data Foundation (ODF fka OCS) on top of it
* make masters schedulable to deploy ODF on top of it
* make masters also infra nodes and move routers, registry, monitoring and logging to infra nodes
  * change default scheduler and label workers to avoid workload being scheduled to infra nodes
  * there is no need that masters need to become infra nodes, so this could be done on any node labeled accordingly with the infra role
* validae cluster and upgrade to latest to verify a functioning cluster
    
All files used to create objects in OCP should be in the appropriate subfolders coming with that git repo so you can simply follow along, however, you may have to change names and sizes according to your setup.
In addition, if you want to move any infra workload on dedicated infra nodes and not masters, you may want to consider also tainting infra nodes as shown by [Infrastructure Nodes in OpenShift 4](https://access.redhat.com/solutions/5034771)to avoid the need of changing the default scheduler.

**Mind**
* At time of writing this, depending on the version you're using ```oc debug node/<nodename>``` and ```oc adm must-gather``` may have issues due to [bug 1812813](https://bugzilla.redhat.com/show_bug.cgi?id=1812813). For a workaround, please check [oc debug node Fails When a Default nodeSelector is Defined](https://access.redhat.com/solutions/4982331)

**Steps by step :**

* [Setup aws tools and install ocp tools on your local laptop](docs/Setup_aws_tools_and_install_ocp_tools_on_your_local_laptop.md)
* [Create install-config.yaml and deploy cluster](docs/Create_install-config.yaml_and_deploy_cluster.md)
* [Set up bastion and iscsi host](docs/Set_up_bastion_and_iscsi_host.md)
* [Connect to jumphost and iscsi instance](docs/Connect_to_jumphost_and_iscsi_instance.md)
* [Create iscsi target and map to hosts](docs/Create_iscsi_target_and_map_to_hosts.md)
* [Login to target and automate this via mc](docs/Login_to_target_and_automate_this_via_mc.md)
* [Make masters schedulable and label for ODF](docs/Make_masters_schedulable_andlabel_for_ODF.md)
* [Deploy LSO](docs/Deploy_LSO.md)
* [Deploy ODF](docs/Deploy_ODF.md)
* [Create infra nodes (masters) and change default scheduler](docs/Create_infra_nodes_masters_and_change_default_scheduler.md)
* [Scale and move routers to infra](docs/Scale_and_move_routers_to_infra.md)
* [Move Registry to ODF, infra nodes and scale](docs/Move_Registry_to_ODF_infra_nodes_and_scale.md)
* [Move monitoring to infra nodes and ODF](docs/Move_monitoring_to_infra_nodes_and_ODF.md)
* [Deploy logging to infra nodes and ODF](docs/Deploy_logging_to_infra_nodes_and_ODF.md)
* [Run test workload to validate scheduling](docs/Run_test_workload_to_validate_scheduling.md)
* [Upgrade](docs/Upgrade.md)


* List of all commands only - TBD
