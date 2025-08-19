# This test verifies successful deployment of a config that specifies
# agent-to-controller connectivity, with authenticated TLS.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.json
# @TEST-EXEC: btest-diff output.ini

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Place the credentials into the local etc folder so they're available inside
# the Docker containers:
cp -pr $FILES/certs etc/

cat >>zeekscripts/local.zeek <<EOF
redef Broker::ssl_cafile = "/usr/local/etc/certs/ca.pem";
redef Broker::ssl_certificate = "/usr/local/etc/certs/cert.1.pem";
redef Broker::ssl_keyfile = "/usr/local/etc/certs/key.1.enc.pem";
redef Broker::ssl_passphrase = "12345";
EOF

cat >>etc/zeek-client.cfg <<EOF
[ssl]
cafile = /usr/local/etc/certs/ca.pem
certificate = /usr/local/etc/certs/cert.1.pem
keyfile = /usr/local/etc/certs/key.1.enc.pem
passphrase = 12345
EOF

docker_compose_up

# The certificate uses common name 1.foo.bar, so make the controller
# available under that name. There are several ways for doing this,
# including at the Docker level, but it seems easiest to just override name
# resolution within the client container:
client_cmd 'echo "$(getent hosts controller | grep controller | awk "{ print \$1 }") 1.foo.bar" >>/etc/hosts'

# Our zeek_client wrapper honors this:
export TEST_ZEEK_CLIENT_ARGS="--set controller.host=1.foo.bar"

. $TEST_BASE/tests/deploy-a2c-common.sh
