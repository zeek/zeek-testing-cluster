# This test verifies get-nodes output with and without any existing deployment.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.bare
# @TEST-EXEC: btest-diff output.nodes

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# Don't exit on error from now on since we want to examine exit codes.
set +e

zeek_client get-nodes >output.bare && fail "get-nodes did not fail on missing deployment"

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings. Deploy a small
# cluster:

cat $FILES/config.ini | zeek_client set-config -

wait_for_all_nodes_running || fail "nodes did not end up running"

# Strip the PIDs, since they change from run to run.
zeek_client get-nodes | jq 'del(.results[][].pid)' >output.nodes
