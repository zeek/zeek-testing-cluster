# Verify that Prometheus metrics ports auto-assignment leads to ports across the
# cluster as expected. This uses a single-host scenario with the (somewhat
# unusual) scenario of multiple instances running on it. The point to look out
# for here is that port assignment doesn't clash.
#
# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# The testsuite disables metrics port auto-assignment, re-enable:
cat >>zeekscripts/controller-local.zeek <<EOF
redef Management::Controller::auto_assign_metrics_ports = T;
EOF

# Run a "bare" controller without agents:
ZEEK_ENTRYPOINT=controller.zeek docker_compose_up

# Run two agents alongside, both connecting to the controller:
docker_exec controller mkdir /tmp/agent1 /tmp/agent2

docker_exec -d -w /tmp/agent1 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::name=agent-inst1 \
    Broker::default_port=10000/tcp

# The second agent still needs a listening port because cluster nodes created by
# agents always peer with them.
docker_exec -d -w /tmp/agent2 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::default_port=2152/tcp \
    Management::Agent::name=agent-inst2 \
    Broker::default_port=10001/tcp

# Give agents time to connect to the controller.
wait_for_instances 2

# Add curl in the client container. We do this at runtime so it works with both
# this testsuite's development container and the official Zeek one, as built in
# our regular CI.
client_cmd "apt-get -q update && apt-get install -q -y --no-install-recommends curl"

# We need the IP address of the controller (which runs everything -- agents &
# cluster) so we can put it in place throughout the configuration.
controller_ip=$(client_cmd "getent hosts controller" | cut -d' ' -f1)

# We're not providing names to the agents launched via docker-compose, so this
# uses auto-generated names:
zeek_client deploy-config - <<EOF
[instances]
agent-inst1
agent-inst2

[manager]
instance = agent-inst1
role = manager

[logger]
instance = agent-inst1
role = logger

[worker]
instance = agent-inst2
role = worker
interface = eth0
EOF

wait_for_all_nodes_running || fail "nodes did not end up running"

# The manager exposes a discovery endpoint:
client_cmd "curl -s http://controller:9000/services.json" \
    | jq '.[].targets |= sort' >output.manager-sd.json

# All nodes expose telemetry, grab it:
client_cmd "curl -s http://controller:9000/metrics" >output.manager.dat
client_cmd "curl -s http://controller:9001/metrics" >output.logger.dat
client_cmd "curl -s http://controller:9002/metrics" >output.worker.dat

# Smoke-test presence of the version info:
grep -q zeek_version_info output.manager.dat
grep -q zeek_version_info output.logger.dat
grep -q zeek_version_info output.worker.dat

# Verify the node identities are as we expect:
grep -q 'endpoint="manager"' output.manager.dat
grep -q 'endpoint="logger"' output.logger.dat
grep -q 'endpoint="worker"' output.worker.dat
