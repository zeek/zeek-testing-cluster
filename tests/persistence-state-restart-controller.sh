# This test verifies that when a controller with a deployed configuration
# restarts, the running Zeek cluster does change (i.e., its processes still have
# the same PIDs), because the agents are still running that same configuration.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# This needs "ps" and "sqlite3":
controller_cmd "apt-get -q update && apt-get install -q -y --no-install-recommends procps sqlite3"

# Deploy a Zeek cluster and give its nodes time to come up:
cat $FILES/config.ini | zeek_client deploy-config -
wait_for_all_nodes_running || fail "nodes did not end up running"

# Ensure the controller has persisted the deployed configuration:
try_until controller_cmd 'sqlite3 $(zeek-config --prefix)/var/lib/nodes/controller/___sync_store_*::g_configs.sqlite "select key from store" | grep -q DEPLOYED' \
    || fail "deployed config did not appear in SQL"

# Remember this node layout:
n1=$(zeek_client get-nodes)
echo "Nodes before: $n1"

# Kill the controller. The Supervisor will restart it.
controller_cmd 'kill $(ps xc | grep zeek.controller | awk "{ print \$1 }")'

# Wait until the cluster is back up. We should have 5 nodes: controller and
# agent, as well as a manager, logger, and worker (per $FILES/config.ini).
wait_for_all_nodes_running 5 || fail "nodes did not end up running"

# Get new layout:
n2=$(zeek_client get-nodes)
echo "Nodes after: $n2"

# The following nodes should be the same ...
assert_get_nodes_pids "$n1" "$n2" equal instance-1
assert_get_nodes_pids "$n1" "$n2" equal manager
assert_get_nodes_pids "$n1" "$n2" equal logger
assert_get_nodes_pids "$n1" "$n2" equal worker

# ... and the controller should differ, since we restarted it.
assert_get_nodes_pids "$n1" "$n2" unequal controller
