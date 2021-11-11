@load policy/frameworks/cluster/agent
@load ./agent-local.zeek

redef ClusterAgent::directory = "/var/log/zeek/mgmt";
redef ClusterAgent::cluster_directory = "/var/log/zeek/cluster";
