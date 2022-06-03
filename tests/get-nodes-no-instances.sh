# This test verifies get-nodes output with no connected instances

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Only run the controller
ZEEK_ENTRYPOINT=controller.zeek docker_compose_up

# Don't exit on error from now on since we want to examine exit codes.
set +e

# The controller should report an error and exit with error.
zeek_client get-nodes >output && fail "get-nodes did not fail without connected instances"

true
