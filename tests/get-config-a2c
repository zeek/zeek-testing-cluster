# This test verifies the behavior of the client's get-config command. We:
# - Verify error response when retrieving config without prior deployment
# - Deploy a configuration
# - Retrieve it as JSON and verify the output
# - Retrieve it again, as INI, and verify the output
# - Deploy the returned INI again as a new configuration
# - Verify the resulting config once more.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.error
# @TEST-EXEC: btest-diff output.json
# @TEST-EXEC: btest-diff output.ini
# @TEST-EXEC: btest-diff output-redeploy.json

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.

zeek_client get-config >output.error 2>&1 \
    && fail "zeek-client get-config without deployment did not fail"

# Everything else should succeed.

zeek_client set-config - <<EOF
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
zeek_client get-config --as-json | jq 'del(.id)' >output.json

# The INI format does not include the ID field.
zeek_client get-config >output.ini

# Subtle: the above produced the output files locally, not in the Docker
# container. If we just provide, say, "output.ini" now, zeek-client will look
# for it inside the container and fail to find it. We use stdin to work around
# this.
cat output.ini | zeek_client set-config -
wait_for_all_nodes_running || fail "nodes did not end up running"

zeek_client get-config --as-json | jq 'del(.id)' >output-redeploy.json
