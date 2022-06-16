# This test verifies successful deployment of a config that specifies
# agent-to-controller connectivity.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.json
# @TEST-EXEC: btest-diff output.ini

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.

zeek_client deploy-config - <<EOF
[instances]
instance-1

[manager]
instance = instance-1
port = 5000
role = manager

[logger-01]
instance = instance-1
port = 5001
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

wait_for_all_nodes_running || fail "nodes did not end up running"

# Remove the id field (containing the deployed configuration's UUID),
# so we can diff it.
zeek_client get-config --as-json --deployed | jq 'del(.id)' >output.json

# The INI format does not include the ID field.
zeek_client get-config --deployed >output.ini
