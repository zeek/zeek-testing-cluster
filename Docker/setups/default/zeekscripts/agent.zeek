@load policy/frameworks/management/agent

redef Management::Agent::directory = "/var/log/zeek/mgmt";
redef Management::Agent::cluster_directory = "/var/log/zeek/cluster";
redef Management::Agent::controller = [$address="controller", $bound_port=2150/tcp];
