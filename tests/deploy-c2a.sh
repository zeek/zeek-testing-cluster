# This test verifies successful deployment of a config that specifies
# controller-to-agent connectivity.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.json
# @TEST-EXEC: btest-diff output.ini

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Configure the agent to listen instead of connecting to controller:
cat >>zeekscripts/agent-local.zeek <<EOF
redef Management::Agent::controller = [\$address="0.0.0.0", \$bound_port=0/unknown];
EOF

docker_compose_up

zeek_client deploy-config - <<EOF
[instances]
instance-1 = 127.0.0.1:2151

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
zeek_client get-config --as-json --deployed | tee output.zc.json | jq 'del(.id)' >output.json

# The INI format does not include the ID field.
zeek_client get-config --deployed >output.ini
