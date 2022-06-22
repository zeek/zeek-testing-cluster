# This test verifies that the controller complains about configs in which
# nodes indicate running on instances that the config does not declare.

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

zeek_client stage-config - >output <<EOF
[instances]
instance-1

[manager]
instance = instance-2
role = manager

[worker]
instance = instance-3
role = worker
interface = eth0
EOF

[ $? -ne 0 ] || fail "stage-config succeeded on invalid configuration"

true
