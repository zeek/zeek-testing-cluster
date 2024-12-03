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

# For minimal deployment (without spelling out instances etc) to work, we need
# to run on the controller machine:
controller_cmd zeek-client -c /usr/local/etc/zeek-client.cfg deploy-config - <<EOF
[manager]
role = manager
scripts = testing/manager.zeek
env = SENDER=proxy

[proxy]
role = proxy
scripts = testing/sender.zeek
env = SENDER=proxy ZEEK_DEFAULT_CONNECT_RETRY=5

[worker]
role = worker
scripts = testing/receiver.zeek
interface = lo
env = SENDER=proxy ZEEK_DEFAULT_CONNECT_RETRY=5
EOF

wait_for_all_nodes_running || fail "nodes did not end up running"

proxy_logs=/usr/local/zeek/var/lib/nodes/proxy
worker_logs=/usr/local/zeek/var/lib/nodes/worker
manager_logs=/usr/local/zeek/var/lib/nodes/manager

# Nodes are up. Verify that the worker locks up in the script layer:
try_until -d 20 -i 1 controller_cmd "grep WEDGING $worker_logs/stdout" \
    || fail "worker never ended up wedging"

# Now wait until the proxy sees backpressure-induced unpeering. This can take a while.
try_until -d 60 -i 1 controller_cmd "grep 'removed due to backpressure' $proxy_logs/cluster.log" \
    || fail "proxy never saw backpressure"

# Un-wedge the worker:
controller_cmd "touch /tmp/zeek-unwedge"

# Verify this worked -- that should be quick:
try_until controller_cmd "grep UNWEDGED $worker_logs/stdout" \
    || fail "worker never got unwedged"

# Now verify connectivity recovered, in the worker...
try_until -d 30 controller_cmd "grep RECOVERED $worker_logs/stdout" \
    || fail "worker never recovered"

# ... and in the proxy's cluster.log. We look for a hello from the worker after
# the backpressure overflow notification.
try_until -d 10 controller_cmd "cat $proxy_logs/cluster.log " \
    "| awk 'f{print} /removed due to backpressure/{f=1}' " \
    "| grep 'got hello from worker'"

# The proxy's telemetry also should report the unpeering by now.
# "proxy,worker" captures that the proxy observed the worker falling behind.
try_until controller_cmd "cat $proxy_logs/telemetry.log " \
    "| grep -E 'zeek_broker_backpressure_disconnects_total.+proxy,worker.+1.0'" \
    || fail "telemetry did not report backpressure disconnect"

# Verify that the manager never detected a lockup.
controller_cmd "grep -q -v LOCKUP $manager_logs/stdout" \
    || fail "manager diagnosed a sender lockup"
