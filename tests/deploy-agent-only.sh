# This test verifies that the controller recognizes configs that only list
# instances, no nodes.

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

zeek_client deploy-config - <<EOF | tee output.zc | jq '.results.id = "xxx"' >output
[instances]
instance-1
EOF
