# This test verifies that the restart of an agent currently running cluster
# nodes leads to re-establishment of those cluster nodes. The restarted agent
# will check in with the controller, which re-deploys the configuration to it,
# leading to node re-launch. We verify change by comparing node PIDs.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Run a "bare" controller without agents:
ZEEK_ENTRYPOINT=controller.zeek docker_compose_up

# Run two agents alongside, both connecting to the controller:
docker_exec controller mkdir /tmp/agent1 /tmp/agent2
docker_exec -d -w /tmp/agent1 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::name=instance-1 \
    Broker::default_port=10000/tcp
# The second agent still needs a listening port because cluster nodes created by
# agents always peer with them.
docker_exec -d -w /tmp/agent2 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::default_port=2152/tcp \
    Management::Agent::name=instance-2 \
    Broker::default_port=10001/tcp

# Give agents time to connect to the controller:
wait_for_instances 2

# This needs "ps":
controller_cmd "apt-get -q update && apt-get install -q -y --no-install-recommends procps"

# Deploy a Zeek cluster and give its nodes time to come up. We deploy across two
# agents so we can verify that restarting one agent only restarts that agent's
# nodes, not the full cluster.
zeek_client deploy-config - <<EOF
[manager]
instance = instance-1
role = manager

[logger-01]
instance = instance-1
role = logger

[worker-01]
instance = instance-2
role = worker
interface = eth0

[worker-02]
instance = instance-2
role = worker
interface = lo
EOF

wait_for_all_nodes_running || fail "nodes did not end up running"

# Remember this node layout:
n1=$(zeek_client get-nodes)
echo "Nodes before: $n1"

# Kill the agent. The Supervisor will restart it.
controller_cmd 'kill $(ps xc | grep zeek.instance-1 | awk "{ print \$1 }")'

# Wait until the cluster is back up. We should have 6 nodes: 2 agents plus the 4
# cluster nodes shown above. The controller doesn't show up, as it's running in
# a separate process tree.
wait_for_all_nodes_running 6 || fail "restarted nodes did not end up running"

# Get new layout:
n2=$(zeek_client get-nodes)
echo "Nodes after: $n2"

# The following nodes should be the same ...
assert_get_nodes_pids "$n1" "$n2" equal instance-2
assert_get_nodes_pids "$n1" "$n2" equal worker-01
assert_get_nodes_pids "$n1" "$n2" equal worker-02

# ... and these should differ, since we restarted them.
assert_get_nodes_pids "$n1" "$n2" unequal instance-1
assert_get_nodes_pids "$n1" "$n2" unequal manager
assert_get_nodes_pids "$n1" "$n2" unequal logger-01
