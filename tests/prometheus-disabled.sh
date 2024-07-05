# Verifies that when disabling auto-enumeration and not providing any metrics
# ports, scraping endpoints don't become available.
#
# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# The testsuite already disables metrics port auto-assignment.

# Enable Prometheus ports in the created nodes -- but there should be none.
cat >>zeekscripts/agent-local.zeek <<EOF
@load frameworks/telemetry/prometheus
EOF

docker_compose_up

# Add curl in the client container. We do this at runtime so it works with both
# this testsuite's development container and the official Zeek one, as built in
# our regular CI.
client_cmd "apt-get -q update && apt-get install -q -y --no-install-recommends curl"

zeek_client deploy-config - <<EOF
[instances]
instance-1

[manager]
instance = instance-1
role = manager
scripts = misc/loaded-scripts

[logger]
instance = instance-1
role = logger

[worker]
instance = instance-1
role = worker
interface = eth0
EOF

wait_for_all_nodes_running || fail "nodes did not end up running"

# The prometheus-defaults test verifies that our start port assumption holds.

# The manager should not expose a discovery endpoint:
if client_cmd "curl -s http://controller:9090/services.json"; then
    fail "service discovery unexpectedly available"
fi
# The manager, logger, and worker all should not expose telemetry:
if client_cmd "curl -s http://controller:9090/metrics"; then
    fail "manager telemetry unexpectedly scrapable"
fi
if client_cmd "curl -s http://controller:9091/metrics"; then
    fail "logger telemetry unexpectedly scrapable"
fi
if client_cmd "curl -s http://controller:9092/metrics"; then
    fail "worker telemetry unexpectedly scrapable"
fi
