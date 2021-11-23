@load policy/frameworks/cluster/agent
@load ./agent-local.zeek

redef ClusterAgent::directory = "/var/log/zeek/mgmt";
redef ClusterAgent::cluster_directory = "/var/log/zeek/cluster";
redef ClusterAgent::controller = [$address="127.0.0.1", $bound_port=2150/tcp];
