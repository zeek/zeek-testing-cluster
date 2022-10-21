# This test verifies successful deployment of a config that specifies
# agent-to-controller connectivity, with cleartext communication.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.json
# @TEST-EXEC: btest-diff output.ini

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

cat >>zeekscripts/local.zeek <<EOF
redef Broker::disable_ssl = T;
EOF

cat >>etc/zeek-client.cfg <<EOF
[ssl]
disable = true
EOF

docker_compose_up

. $TEST_BASE/tests/deploy-a2c-common.sh
