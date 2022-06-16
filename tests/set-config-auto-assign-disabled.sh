# This test verifies that the client gets an error response when uploading a
# configuration missing ports, with port auto-allocation disabled.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Disable auto-assignment
cat >>zeekscripts/controller-local.zeek <<EOF
redef Management::Controller::auto_assign_ports = F;
EOF

docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.

# Don't exit on error from now on since we want to examine exit codes.
set +e

zeek_client set-config - >output <<EOF
[instances]
instance-1

[manager]
instance = instance-1
role = manager

[logger-01]
instance = instance-1
role = logger

[proxy-01]
instance = instance-1
role = proxy

[worker-01]
instance = instance-1
role = worker
interface = eth0
EOF

[ $? -ne 0 ] || fail "zeek-client did not exit with error"
