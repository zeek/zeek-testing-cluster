# Verify that Prometheus metrics ports auto-assignment leads to ports across the
# cluster as expected.
#
# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate multihost

# The testsuite disables metrics port auto-assignment, re-enable:
cat >>zeekscripts/controller-local.zeek <<EOF
redef Management::Controller::auto_assign_metrics_ports = T;
EOF

# Enable Prometheus ports in the created nodes. This technically applies to the
# agent too, but since it's not running a cluster has no effect there. We could
# alternatively also specify an extra script to load for every node in the
# cluster config.
cat >>zeekscripts/agent-local.zeek <<EOF
@load frameworks/telemetry/prometheus
EOF

docker_compose_up

# Add curl in the client container. We do this at runtime so it works with both
# this testsuite's development container and the official Zeek one, as built in
# our regular CI.
client_cmd "apt-get -q update && apt-get install -q -y --no-install-recommends curl"

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

# To verify that service discovery shows the right IP addresses, we need to
# retrieve them first.
inst1_ip=$(client_cmd "getent hosts inst1" | cut -d' ' -f1)
inst2_ip=$(client_cmd "getent hosts inst2" | cut -d' ' -f1)

# The manager exposes a discovery endpoint. We don't baseline it because its IP
# addresses will differ from run to run. We can do better once we support
# hostnames as well.
client_cmd "curl -s http://inst1:9000/services.json" \
    | jq '.[].targets |= sort' >output.manager-sd.json

for hostport in $(jq -r '.[0].targets | join(" ")' output.manager-sd.json); do
    host=$(echo "$hostport" | cut -d: -f1)
    if [[ $host != $inst1_ip ]] && [[ $host != $inst2_ip ]]; then
        fail "unexpected host in service discovery: $host"
    fi
done

# All nodes expose telemetry, grab it:
client_cmd "curl -s http://inst1:9000/metrics" >output.manager.dat
client_cmd "curl -s http://inst1:9001/metrics" >output.logger.dat
client_cmd "curl -s http://inst2:9002/metrics" >output.worker.dat

# Smoke-test presence of the version info:
grep -q zeek_version_info output.manager.dat
grep -q zeek_version_info output.logger.dat
grep -q zeek_version_info output.worker.dat

# Verify the node identities are as we expect:
grep -q 'endpoint="manager"' output.manager.dat
grep -q 'endpoint="logger"' output.logger.dat
grep -q 'endpoint="worker"' output.worker.dat
