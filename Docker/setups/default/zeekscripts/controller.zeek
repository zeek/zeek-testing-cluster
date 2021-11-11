@load policy/frameworks/cluster/controller

redef ClusterController::directory = "/var/log/zeek/mgmt";

#redef ClusterController::instances = {
#	["inst1"] = ClusterController::Types::Instance($name="", $host="inst1", $listen_port=2151/tcp),
#	["inst2"] = ClusterController::Types::Instance($name="", $host="inst2", $listen_port=2151/tcp),
#};
