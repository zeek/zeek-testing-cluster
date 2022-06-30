# This test verifies successful deployment of a minimal cluster config
# mentioning no instances, i.e. where running on the local system is implied.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.json

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Set agent name back to its default (the empty string), so the framework falls
# back to using "agent-<hostname>"
cat >>zeekscripts/agent-local.zeek <<EOF
redef Management::Agent::name = "";
EOF

docker_compose_up

# For the minimal deployment to work, we need to run it locally on the
# controller machine, not as in the other tests from its own container:
controller_cmd zeek-client -c /usr/local/etc/zeek-client.cfg deploy-config - <<EOF
[manager]
role = manager

[logger]
role = logger

[worker-01]
role = worker
interface = lo

[worker-02]
role = worker
interface = eth0
EOF

wait_for_all_nodes_running || fail "nodes did not end up running"

zeek_client get-config --as-json --deployed | jq 'del(.id)' >output.json
