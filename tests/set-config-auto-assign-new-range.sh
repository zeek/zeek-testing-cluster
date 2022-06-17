# This test verifies port auto-assignment in a cluster config, with a tweaked
# setting that changes the start port.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.staged
# @TEST-EXEC: btest-diff output.deployed

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Change the start port for auto-assignment:
cat >>zeekscripts/controller-local.zeek <<EOF
redef Management::Controller::auto_assign_start_port = 3000/tcp;
EOF

docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.

zeek_client deploy-config - <<EOF
[instances]
instance-1

[manager]
instance = instance-1
role = manager

[logger-01]
instance = instance-1
role = logger

[proxy-01]
instance = instance-1
role = proxy

[worker-01]
instance = instance-1
role = worker
interface = eth0
EOF

zeek_client get-config --as-json | jq '.id = "xxx"' >output.staged
zeek_client get-config --as-json --deployed | jq '.id = "xxx"' >output.deployed
