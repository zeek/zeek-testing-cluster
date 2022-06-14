# This test verifies that the controller complains about configs in which
# multiple nodes request the same port, and complains only once per instance.

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
instance-2

[manager]
instance = instance-1
port = 5000
role = manager

[worker1]
instance = instance-1
port = 5000
role = worker
interface = eth0

[worker2]
instance = instance-1
port = 5000
role = worker
interface = eth0

[worker3]
instance = instance-2
port = 5000
role = worker
interface = eth0
EOF

[ $? -ne 0 ] || fail "set-config succeeded on invalid configuration"

true
