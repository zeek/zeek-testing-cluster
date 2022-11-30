# This test verifies the behavior of the client's get-id-value command. We first
# deploy a configuration across two agents, then check variations of the command.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

btest_diff() {
    local input="$1"
    btest-diff $input || fail "btest-diff failed on $input"
}

docker_populate singlehost

# Set GetIdValuesTest::log_streams with the Log::Stream for conn.log and
# dns.log for querying through via zeek_client.
cat >>zeekscripts/local.zeek <<EOF
module GetIdValuesTest;

export {
    global log_streams: table[Log::ID] of Log::Stream;
}

event zeek_init() &priority=-1000
	{
@ifdef ( Conn::LOG )
	log_streams[Conn::LOG] = Log::active_streams[Conn::LOG];
@endif

@ifdef ( DNS::LOG )
	log_streams[DNS::LOG] = Log::active_streams[DNS::LOG];
@endif
	}
EOF

# Run a "bare" controller without agents:
ZEEK_ENTRYPOINT=controller.zeek docker_compose_up

# Run two agents alongside, both connecting to the controller:
docker_exec controller mkdir /tmp/agent1 /tmp/agent2

docker_exec -d -w /tmp/agent1 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::name=instance-1 \
    Broker::default_port=10000/tcp

# The second agent still needs a listening port because cluster nodes created by
# agents always peer with them.
docker_exec -d -w /tmp/agent2 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::default_port=2152/tcp \
    Management::Agent::name=instance-2 \
    Broker::default_port=10001/tcp

# Don't exit on error since we want to examine exit codes.
set +e

# Attempt an ID retrieval without a deployed cluster. This should fail.
run "zeek_client get-id-value bits_per_uid | jq" 1 nocluster
btest_diff output.nocluster

# Deploy a small cluster across the two agents.

zeek_client deploy-config - <<EOF
[instances]
instance-1
instance-2

[manager]
instance = instance-1
port = 5000
role = manager

[logger-01]
instance = instance-1
port = 5001
role = logger

[worker-01]
instance = instance-2
role = worker
interface = eth0

[worker-02]
instance = instance-2
role = worker
interface = lo
EOF

[ $? -eq 0 ] || fail "zeek-client deploy-config failed"

wait_for_all_nodes_running || fail "nodes did not end up running"

# On to why we're here -- variations of "zeek-client get-id-value"

# Retrieve a basic value that exists on all nodes:
run "zeek_client get-id-value bits_per_uid" 0 simple
btest_diff output.simple

# Retrieve a variable that does not exist:
run "zeek_client get-id-value this_is_not_defined" 1 unknown
btest_diff output.unknown

# Retrieve a thing that exists but is not a value:
run "zeek_client get-id-value connection" 1 noid
btest_diff output.noid

# Retrieve a more complex value:
run "zeek_client get-id-value GetIdValuesTest::log_streams" 0 complex
btest_diff output.complex

# Retrieve from a single, existing node:
run "zeek_client get-id-value bits_per_uid manager" 0 nodes-single
btest_diff output.nodes-single

# Retrieve from select existing nodes:
run "zeek_client get-id-value bits_per_uid manager logger-01" 0 nodes-multiple
btest_diff output.nodes-multiple

# Retrieve from select nodes, including invalid ones
run "zeek_client get-id-value bits_per_uid worker-02 worker-03" 1 nodes-mixed
btest_diff output.nodes-mixed

# Retrieve from select nodes that do not exist at all
run "zeek_client get-id-value bits_per_uid worker-03 worker-04" 1 nodes-invalid
btest_diff output.nodes-invalid
