# This test verifies that the controller complains about configs in which
# nodes request the default agent port.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.
wait_for_instances 1

# Don't exit on error since we want to examine exit codes.
set +e

zeek_client stage-config - >output <<EOF
[instances]
instance-1 = 127.0.0.1:3000

[manager]
instance = instance-1
port = 3000
role = manager

[worker]
instance = instance-1
role = worker
interface = eth0
EOF

[ $? -ne 0 ] || fail "stage-config succeeded on invalid configuration"

true
