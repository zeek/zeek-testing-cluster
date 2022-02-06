@load policy/frameworks/management/agent
@load ./agent-local.zeek

redef Management::Agent::directory = "/var/log/zeek/mgmt";
redef Management::Agent::cluster_directory = "/var/log/zeek/cluster";
