@load policy/frameworks/cluster/controller
@load ./controller-local.zeek

redef ClusterController::directory = "/var/log/zeek/mgmt";
