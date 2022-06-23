# This test verifies the behavior of the client's restart command in different
# scenarios: a sole controller, agents connected but no deployment, restart of
# select existing/nonexisting nodes, and restart of all nodes.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Run a "bare" controller without agents:
ZEEK_ENTRYPOINT=controller.zeek docker_compose_up

print_config() {
    cat <<EOF
[manager]
instance = instance-1
port = 5000
role = manager

[logger]
instance = instance-1
port = 5001
role = logger

[worker1]
instance = instance-2
role = worker
interface = eth0

[worker2]
instance = instance-2
role = worker
interface = lo
EOF
}

deploy() {
    print_config | zeek_client deploy-config -
    wait_for_all_nodes_running || fail "nodes did not end up running"
}

# Restart when we don't even have agents. This should fail.
run "zeek_client restart" 1 noinstances
btest-diff output.noinstances

# Run two agents, both connecting to the controller:
docker_exec controller mkdir /tmp/agent1 /tmp/agent2
docker_exec -d -w /tmp/agent1 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::name=instance-1 \
    Broker::default_port=10000/tcp
docker_exec -d -w /tmp/agent2 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::default_port=2152/tcp \
    Management::Agent::name=instance-2 \
    Broker::default_port=10001/tcp

wait_for_instances 2 || fail "agents did not register"

# Restart when we don't have a cluster. This should fail.
run "zeek_client restart" 1 nocluster
btest-diff output.nocluster

# Now try variations of restarts.

# Restart an unknown node.
deploy
run "zeek_client restart foobar" 1 unknown
btest-diff output.unknown

# Restart a single node.
deploy

n1=$(zeek_client get-nodes)
run "zeek_client restart worker1" 0 one-known
btest-diff output.one-known

wait_for_all_nodes_running || "nodes did not end up running (one-known)"
n2=$(zeek_client get-nodes)

assert_get_nodes_pids "$n1" "$n2" equal manager
assert_get_nodes_pids "$n1" "$n2" equal logger
assert_get_nodes_pids "$n1" "$n2" equal worker2
assert_get_nodes_pids "$n1" "$n2" unequal worker1

# Restart multiple nodes.
deploy

n1=$(zeek_client get-nodes)
run "zeek_client restart logger worker1" 0 two-known
btest-diff output.two-known

wait_for_all_nodes_running || "nodes did not end up running (two-known)"
n2=$(zeek_client get-nodes)

assert_get_nodes_pids "$n1" "$n2" equal manager
assert_get_nodes_pids "$n1" "$n2" equal worker2
assert_get_nodes_pids "$n1" "$n2" unequal logger
assert_get_nodes_pids "$n1" "$n2" unequal worker1

# Restart a mix of known and unknown
deploy

n1=$(zeek_client get-nodes)
run "zeek_client restart logger foobar" 1 mixed
btest-diff output.mixed

wait_for_all_nodes_running || "nodes did not end up running (mixed)"
n2=$(zeek_client get-nodes)

assert_get_nodes_pids "$n1" "$n2" equal manager
assert_get_nodes_pids "$n1" "$n2" equal worker1
assert_get_nodes_pids "$n1" "$n2" equal worker2
assert_get_nodes_pids "$n1" "$n2" unequal logger

# Restart all nodes
deploy

n1=$(zeek_client get-nodes)
run "zeek_client restart" 0 all
btest-diff output.all

wait_for_all_nodes_running || "nodes did not end up running (all)"
n2=$(zeek_client get-nodes)

assert_get_nodes_pids "$n1" "$n2" unequal manager
assert_get_nodes_pids "$n1" "$n2" unequal logger
assert_get_nodes_pids "$n1" "$n2" unequal worker1
assert_get_nodes_pids "$n1" "$n2" unequal worker2
