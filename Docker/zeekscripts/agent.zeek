@load policy/frameworks/cluster/agent

redef ClusterAgent::directory = "/var/log/zeek/mgmt";
redef ClusterAgent::cluster_directory = "/var/log/zeek/cluster";
redef ClusterAgent::controller = [$address="controller", $bound_port=2150/tcp];
