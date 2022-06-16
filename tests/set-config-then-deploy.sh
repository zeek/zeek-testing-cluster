# This test verifies that the client can first set a cluster configuration, then
# deploy it.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.set-config
# @TEST-EXEC: btest-diff output.deploy

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.

zeek_client set-config - <<EOF >output
[instances]
instance-1

[manager]
instance = instance-1
role = manager

[logger-01]
instance = instance-1
role = logger

[worker-01]
instance = instance-1
role = worker
interface = eth0

[worker-02]
instance = instance-1
role = worker
interface = lo
EOF

cat output | jq '.results.id = "xxx"' >output.set-config
cid_set_config=$(cat output | jq -r '.results.id')

zeek_client deploy >output
wait_for_all_nodes_running || fail "nodes did not end up running"

cat output | jq '.results.id = "xxx"' >output.deploy
cid_deploy=$(cat output | jq -r '.results.id')

[ $cid_set_config == $cid_deploy ] \
    || fail "config ID mismatch: ${cid_set_config} vs ${cid_deploy}"
