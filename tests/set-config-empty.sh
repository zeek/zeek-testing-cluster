# This test verifies that the controller recognizes empty configs as a special
# case that it can deploy and respond to immediately.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.

cat /dev/null | zeek_client deploy-config - | jq '.results.id = "xxx"' >output
