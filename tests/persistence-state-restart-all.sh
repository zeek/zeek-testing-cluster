# This test verifies that persisted configurations lead to a running Zeek
# cluster when starting up agents and controller. We deploy a configuration
# (that gets persisted), verify it runs, then shut down agent and controller,
# bring them back up, and verify that the cluster returns.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.staged
# @TEST-EXEC: btest-diff output.deployed
# @TEST-EXEC: btest-diff output.nodes

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Disable log archival, the zeek-archiver can interfere with this test.
cat >>zeekscripts/agent-local.zeek <<EOF
redef Management::Agent::archive_logs = F;
EOF

# Create an override that runs nothing in the controller's container, but keeps
# it alive. We launch our own Supervisor below, so we can kill it without
# stopping the container.
cat >docker-compose.override.yml <<EOF
version: "3"
services:
  controller:
    command: tail -F /dev/null
EOF

docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.

# This needs "ps" and "sqlite3" in the controller's container:
controller_cmd "apt-get -q update && apt-get install -q -y --no-install-recommends procps sqlite3"

# Now launch controller and agent in a new Zeek process tree:
docker_exec -d -- controller /usr/local/zeek/bin/zeek -j site/testing/controller-and-agent.zeek

# Give agent time time to connect to the controller:
wait_for_instances 1

# Deploy a Zeek cluster and give its nodes time to come up:
cat $FILES/config.ini | zeek_client deploy-config -
wait_for_all_nodes_running || fail "nodes did not end up running"

# Ensure the controller has persisted the deployed configuration:
try_until controller_cmd 'sqlite3 $(zeek-config --prefix)/var/lib/nodes/controller/___sync_store_*::g_configs.sqlite "select key from store" | grep -q DEPLOYED' \
    || fail "deployed config did not appear in SQL"

# Shut the whole thing down by killing the Supervisor -- it's the only process
# in "ps ac" output that has no ".<role>" suffix. For example:
#
# $ ps xc | grep zeek
# 2394357 pts/14   Sl+    0:07 zeek <-- Supervisor
# 2394358 pts/14   S      0:00 zeek.stem
# 2394368 pts/14   Sl     0:51 zeek.controller
# ...
#
controller_cmd 'kill $(ps xc | grep zeek$ | awk "{ print \$1 }")'

# Wait until there are no more Zeek processes
try_until controller_cmd "! ps xc | grep -q zeek"

echo "Processes after shutdown:"
controller_cmd 'ps xc'

# Now start the whole thing up again:
docker_exec -d -- controller /usr/local/zeek/bin/zeek -j site/testing/controller-and-agent.zeek

# Collect additional output in case of failure, which is otherwise hard to troubleshoot:
wait_for_instances 1 || fail "agent/controller restart failed"

# We should have staged and deployed configs:
zeek_client get-config >output.staged
zeek_client get-config --deployed >output.deployed

# And, we should have a cluster:
zeek_client get-nodes | tee output.zc.nodes | jq 'del(.results[][].pid)' >output.nodes
