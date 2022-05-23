# This test verifies that log rotation kicks in and puts logs in the expected
# log-queue directory. The test cheats somewhat because it dials the log
# rotation interval way down, which in itself sets a rotation interval. So it
# technically does not verify that log rotation would normally happen.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Speed up log rotation
cat >>zeekscripts/agent-local.zeek <<EOF
redef Log::default_rotation_interval = 1 secs;
EOF

docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings. Deploy a small
# cluster:

cat $FILES/config.ini | zeek_client set-config -

# Don't exit on error from now on since we want to examine exit codes.
set +e

wait_for_all_nodes_running || fail "nodes did not end up running"

# Wait long enough for log rotation to kick in
sleep 2

# We should now have content in the log queue:
run "controller_cmd ls /usr/local/zeek/spool/log-queue | grep -q .log" 0
