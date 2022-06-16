# This test verifies the output of a config deployment that fails to start one
# node.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.

# Let's break the logger:
docker_exec -i -- controller 'echo EEEK >>  $(zeek-config --script_dir)/base/frameworks/cluster/nodes/logger.zeek'

# Don't exit on error from now on since we want to examine exit codes.
set +e

# Deploy a small cluster and collect output:
cat $FILES/config.ini | zeek_client deploy-config - | jq '.results.id = "xxx"' >output

[ $? -ne 0 ] || fail "deploy-config should have failed"
