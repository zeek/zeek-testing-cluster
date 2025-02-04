# This test verifies that Zeek nodes each get their own folder.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# Give agent time to connect to the controller:
wait_for_instances 1

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings. Deploy a small
# cluster:

cat $FILES/config.ini | zeek_client deploy-config -

# Don't exit on error from now on since we want to examine exit codes.
set +e

wait_for_all_nodes_running || fail "nodes did not end up running"

# We should now have a state folder for each active node:
run "controller_cmd test -d /usr/local/zeek/var/lib/nodes/controller" 0
run "controller_cmd test -d /usr/local/zeek/var/lib/nodes/instance-1" 0
run "controller_cmd test -d /usr/local/zeek/var/lib/nodes/logger" 0
run "controller_cmd test -d /usr/local/zeek/var/lib/nodes/manager" 0
run "controller_cmd test -d /usr/local/zeek/var/lib/nodes/worker" 0
