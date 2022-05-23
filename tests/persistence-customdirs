# This test verifies that the user can override persistence folders via
# environment variables.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Establish an alternative var-lib via an early-running zeek_init, so it's there
# by the time the framework wants to use it.
cat >>zeekscripts/local.zeek <<EOF
event zeek_init() &priority=5
      {
      mkdir("/var/lib/zeek");
      }
EOF

# Override default storage locations to use that location:
export ZEEK_MANAGEMENT_SPOOL_DIR=/var/lib/zeek
export ZEEK_MANAGEMENT_STATE_DIR=/var/lib/zeek

docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings. Deploy a small
# cluster:

cat $FILES/config.ini | zeek_client set-config -

# Don't exit on error from now on since we want to examine exit codes.
set +e

wait_for_all_nodes_running || fail "nodes did not end up running"

# We should now have a spool folders in the new location:
run "controller_cmd test -d /var/lib/zeek/nodes/controller" 0
run "controller_cmd test -d /var/lib/zeek/nodes/instance-1" 0
run "controller_cmd test -d /var/lib/zeek/nodes/logger" 0
run "controller_cmd test -d /var/lib/zeek/nodes/manager" 0
run "controller_cmd test -d /var/lib/zeek/nodes/worker" 0
