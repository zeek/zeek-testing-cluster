# This test verifies that the controller complains about instances and nodes of
# the same name.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.

# Don't exit on error since we want to examine exit codes.
set +e

zeek_client set-config - >output <<EOF
[instances]
instance-1

[instance-1]
instance = instance-1
role = manager

[worker]
instance = instance-1
role = worker
interface = eth0
EOF

[ $? -ne 0 ] || fail "set-config succeeded on invalid configuration"

true
