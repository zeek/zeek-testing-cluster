# Verify that Prometheus metrics ports auto-assignment leads to ports across the
# cluster as expected.
#
# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.config-staged
# @TEST-EXEC: btest-diff output.config-deployed
# @TEST-EXEC: btest-diff output.manager-sd.json

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# The testsuite disables auto-assignment, re-enable them:
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

# Verify that our auto-enumeration start point is the default 9000.
# (Would be nicer to query that from the controller itself, but
# get-id-value currently only works for cluster nodes.)
zeek_client "get-id-value Management::Controller::auto_assign_metrics_start_port worker" \
    | jq -e '.results.worker.port == 9000'

# The manager exposes a discovery endpoint. Sort its entries for baselining:
client_cmd "curl -s http://controller:9000/services.json" \
    | jq '.[].targets |= sort' >output.manager-sd.json

# All nodes expose telemetry, grab it:
client_cmd "curl -s http://controller:9000/metrics >/tmp/run/output.manager.dat"
client_cmd "curl -s http://controller:9001/metrics >/tmp/run/output.logger.dat"
client_cmd "curl -s http://controller:9002/metrics >/tmp/run/output.worker.dat"

# Smoke-test presence of the version info:
grep -q zeek_version_info ./services/client/run/output.manager.dat
grep -q zeek_version_info ./services/client/run/output.logger.dat
grep -q zeek_version_info ./services/client/run/output.worker.dat

# Verify the node identities are as we expect:
# Verify the node identities are as we expect:
grep -q 'endpoint="manager"' ./services/client/run/output.manager.dat
grep -q 'endpoint="logger"' ./services/client/run/output.logger.dat
grep -q 'endpoint="worker"' ./services/client/run/output.worker.dat
