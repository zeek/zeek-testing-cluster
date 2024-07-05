# Verify that Prometheus metrics ports auto-assignment, with a tweaked start
# port, leads to expected live ports across the cluster and discoverability.
#
# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.config-staged
# @TEST-EXEC: btest-diff output.config-deployed
# @TEST-EXEC: btest-diff output.manager-sd.json

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# The testsuite disables metrics port auto-assignment, re-enable and tweak start port:
cat >>zeekscripts/controller-local.zeek <<EOF
redef Management::Controller::auto_assign_metrics_ports = T;
redef Management::Controller::auto_assign_metrics_start_port = 3000/tcp;
EOF

# Enable Prometheus ports in the created nodes. This technically applies to the
# agent too, but since it's not running a cluster has no effect there. We could
# alternatively also specify an extra script to load for every node in the
# cluster config.
cat >>zeekscripts/agent-local.zeek <<EOF
@load frameworks/telemetry/prometheus
EOF

# Open up additional ports in the all-in-one container, so we can scrape from
# the modified port range.
cat >docker-compose.override.yml <<EOF
services:
  controller:
    expose:
      - "3000-3002"
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

[logger]
instance = instance-1
role = logger

[worker]
instance = instance-1
role = worker
interface = eth0
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

# All nodes expose telemetry. Smoke-test presence of the version info:
client_cmd "curl -s http://controller:3000/metrics" | tee output.manager.dat | grep -q zeek_version_info
client_cmd "curl -s http://controller:3001/metrics" | tee output.logger.dat | grep -q zeek_version_info
client_cmd "curl -s http://controller:3002/metrics" | tee output.worker.dat | grep -q zeek_version_info

# Verify the node identities are as we expect:
grep -q 'endpoint="manager"' output.manager.dat
grep -q 'endpoint="logger"' output.logger.dat
grep -q 'endpoint="worker"' output.worker.dat
