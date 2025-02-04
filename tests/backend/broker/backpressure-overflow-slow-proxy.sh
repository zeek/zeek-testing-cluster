# @TEST-REQUIRES: $SCRIPTS/docker-requirements
#
# Contents of the "zeekscripts" directory become available to Zeek's containers
# in the "testing" directory, which is part of ZEEKPATH. Most of this happens
# via docker_populate below, but it's handy to use %DIR here.
# @TEST-EXEC: mkdir zeekscripts && cp %DIR/backpressure-overflow/*.zeek zeekscripts
#
# @TEST-EXEC: bash %INPUT

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Set agent name back to its default so the framework falls back to using
# "agent-<hostname>". This allows a minimal deployment config below.
cat >>zeekscripts/agent-local.zeek <<EOF
redef Management::Agent::name = "";
EOF

cat >>zeekscripts/local.zeek <<EOF
@load frameworks/telemetry/log
redef Telemetry::log_interval = 1sec;
EOF

docker_compose_up

# Give agent time to connect to the controller.
wait_for_instances 1

# For minimal deployment (without spelling out instances etc) to work, we need
# to run on the controller machine:
controller_cmd zeek-client -c /usr/local/etc/zeek-client.cfg deploy-config - <<EOF
[manager]
role = manager
scripts = testing/manager.zeek
env = SENDER=worker

[proxy]
role = proxy
scripts = testing/receiver.zeek
env = SENDER=worker ZEEK_DEFAULT_CONNECT_RETRY=5

[worker]
role = worker
scripts = testing/sender.zeek
interface = lo
env = SENDER=worker ZEEK_DEFAULT_CONNECT_RETRY=5
EOF

wait_for_all_nodes_running || fail "nodes did not end up running"

proxy_logs=/usr/local/zeek/var/lib/nodes/proxy
worker_logs=/usr/local/zeek/var/lib/nodes/worker
manager_logs=/usr/local/zeek/var/lib/nodes/manager

# Nodes are up. Verify that the proxy locks up in the script layer:
try_until -d 20 -i 1 controller_cmd "grep WEDGING $proxy_logs/stdout" \
    || fail "proxy never ended up wedging"

# Now wait until the worker sees backpressure-induced unpeering. This can take a while.
try_until -d 60 -i 1 controller_cmd "grep 'removed due to backpressure' $worker_logs/cluster.log" \
    || fail "worker never saw backpressure"

# Un-wedge the proxy:
controller_cmd "touch /tmp/zeek-unwedge"

# Verify this worked -- that should be quick:
try_until controller_cmd "grep UNWEDGED $proxy_logs/stdout" \
    || fail "proxy never got unwedged"

# Now verify connectivity recovered, in the proxy...
try_until -d 30 controller_cmd "grep RECOVERED $proxy_logs/stdout" \
    || fail "proxy never recovered"

# ... and in the worker's cluster.log. We look for a hello from the proxy after
# the backpressure overflow notification.
try_until -d 10 controller_cmd "cat $worker_logs/cluster.log " \
    "| awk 'f{print} /removed due to backpressure/{f=1}' " \
    "| grep 'got hello from proxy'"

# The worker's telemetry also should report the unpeering by now.
# "worker,proxy" captures that the worker observed the proxy falling behind.
try_until controller_cmd "cat $worker_logs/telemetry.log " \
    "| grep -E 'zeek_broker_backpressure_disconnects_total.+worker,proxy.+1.0'" \
    || fail "telemetry did not report backpressure disconnect"

# Verify that the manager never detected a lockup.
controller_cmd "grep -q -v LOCKUP $manager_logs/stdout" \
    || fail "manager diagnosed a sender lockup"
