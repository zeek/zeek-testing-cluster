# This test verifies that the controller complains about configs in which
# multiple nodes request the same port, complains only once per instance, and
# does so the same way via stage-config and deploy-config.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.stage-config
# @TEST-EXEC: btest-diff output.deploy-config

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.

# Don't exit on error since we want to examine exit codes.
set +e

print_config() {
    cat <<EOF
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
}

print_config | zeek_client stage-config - >output.stage-config
[ $? -ne 0 ] || fail "stage-config succeeded on invalid configuration"

print_config | zeek_client deploy-config - >output.deploy-config
[ $? -ne 0 ] || fail "deploy-config succeeded on invalid configuration"

true
