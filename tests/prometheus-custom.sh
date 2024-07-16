# Verifies a custom Prometheus metrics port configuration.
#
# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.config-staged
# @TEST-EXEC: btest-diff output.config-deployed
# @TEST-EXEC: btest-diff output.manager-sd.json

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# The testsuite disables auto-assignment by default.

# Enable Prometheus ports in the created nodes. This technically applies to the
# agent too, but since it's not running a cluster has no effect there. We could
# alternatively also specify an extra script to load for every node in the
# cluster config.
cat >>zeekscripts/agent-local.zeek <<EOF
@load frameworks/telemetry/prometheus
EOF

# Open up additional ports in the all-in-one container, so we can "scrape".
cat >docker-compose.override.yml <<EOF
services:
  controller:
    expose:
      - "3000"
      - "3003"
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
metrics_port = 3000

[logger]
instance = instance-1
role = logger

[worker]
instance = instance-1
role = worker
interface = eth0
metrics_port = 3003
EOF

# Grab config as staged & deployed, focusing on the name, role and metrics port:
zeek_client get-config --as-json \
    | jq '.nodes | map({name,role,metrics_port})' >output.config-staged
zeek_client get-config --as-json --deployed \
    | jq '.nodes | map({name,role,metrics_port})' >output.config-deployed

wait_for_all_nodes_running || fail "nodes did not end up running"

# The manager exposes a discovery endpoint. Sort its entries for baselining:
client_cmd "curl -s http://controller:3000/services.json" \
    | jq '.[].targets |= sort' >output.manager-sd.json

# Only manager and worker expose telemetry:
client_cmd "curl -s http://controller:3000/metrics" >output.manager.dat
client_cmd "curl -s http://controller:3003/metrics" >output.worker.dat

# Smoke-test presence of the version info:
grep -q zeek_version_info output.manager.dat
grep -q zeek_version_info output.worker.dat

# Verify the node identities are as we expect:
grep -q 'endpoint="manager"' output.manager.dat
grep -q 'endpoint="worker"' output.worker.dat
