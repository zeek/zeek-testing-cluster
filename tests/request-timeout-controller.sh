# This test verifies that the client times out when not receiving expected
# controller responses. This only requires a controller, no agents.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

ZEEK_ENTRYPOINT=controller.zeek docker_populate singlehost

docker_compose_up

# Since the client receives no response, it reports the error to stderr. The
# timeout makes zeek-client exit with error, so fail the test if it does not.
zeek_client --set client.request_timeout_secs=3 test-timeout 2>output \
    && fail "test-timeout should have failed" || true
