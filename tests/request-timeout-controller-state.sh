# This test verifies that the controller times out "dangling" client requests
# and sends a corresponding timeout response event back to the client.
# This only requires a controller, no agents.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

ZEEK_ENTRYPOINT=controller.zeek docker_populate singlehost

# Adjust timeouts to speed up the overall testing.

cat >>zeekscripts/controller-local.zeek <<EOF
redef Management::Request::timeout_interval = 1sec;

# We need to redefine this down, otherwise the low request timeout
# will be masked by the higher table-checking default value of 10sec:
redef table_expire_interval = 1sec;
EOF

docker_compose_up

# The client does receive a response, indicating a controller-side timeout.
# The client succeeds in this case, as it's the purpose of the test.
zeek_client --set client.request_timeout_secs=15 test-timeout --with-state >output \
    || fail "test-timeout failed"
