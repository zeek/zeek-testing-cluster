# This test verifies that the client can deploy a cluster configuration
# without explicit ports for manager/logger/proxy, and that the controller
# auto-assigns those by default.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.

zeek_client set-config - <<EOF
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
# Define one port to make sure it remains:
port = 1234

[worker-01]
instance = instance-1
role = worker
interface = eth0
EOF

zeek_client get-config --as-json | jq '.id = "xxx"' >output
