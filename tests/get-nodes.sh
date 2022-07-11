# This test verifies get-nodes output with and without a cluster deployment.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.bare
# @TEST-EXEC: btest-diff output.nodes

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# Give agent time time to connect to the controller:
wait_for_instances 1

# We now run a controller named "controller" and an agent named "instance-1"
# that connects to it, with default settings.

# Don't exit on error from now on since we want to examine exit codes.
set +e

# The controller should see the instance and its Zeek nodes: an agent and the
# controller. (Strip the PIDs, since they change from run to run.)
zeek_client get-nodes | tee output.zc.bare | jq 'del(.results[][].pid)' >output.bare \
    || fail "get-nodes failed with connected instance"

# Deploy a Zeek cluster and give its nodes time to come up:
cat $FILES/config.ini | zeek_client deploy-config -
wait_for_all_nodes_running || fail "nodes did not end up running"

# All nodes should now be there.
zeek_client get-nodes | tee output.zc.nodes | jq 'del(.results[][].pid)' >output.nodes
