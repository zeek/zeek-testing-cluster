# This test verifies port auto-assignment across multiple instances: we expect
# ports to be unique globally.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
ZEEK_ENTRYPOINT=controller.zeek docker_compose_up

# Run two agents alongside the controller that connect to it.
#
docker_exec controller mkdir /tmp/agent1 /tmp/agent2
docker_exec -d -w /tmp/agent1 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::name=instance-1 Broker::default_port=10000/tcp
docker_exec -d -w /tmp/agent2 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::default_port=2152/tcp \
    Management::Agent::name=instance-2 Broker::default_port=10001/tcp

# Give both agents time to connect to the controller:
wait_for_instances 2

zeek_client deploy-config - <<EOF
[manager]
instance = instance-1
role = manager

[logger-01]
instance = instance-1
role = logger

[proxy-01]
instance = instance-1
role = proxy

[proxy-02]
instance = instance-1
role = proxy

[logger-02]
instance = instance-2
role = logger

[proxy-03]
instance = instance-2
role = proxy

[proxy-04]
instance = instance-2
role = proxy

[worker-01]
instance = instance-2
role = worker
interface = eth0
EOF

wait_for_all_nodes_running || fail "nodes did not end up running"

# Remove PIDs from the nodes, and show only Zeek cluster nodes:
zeek_client get-nodes | jq 'del(.results[][].pid).results[] | with_entries(select(.value.cluster_role != null))' >output
