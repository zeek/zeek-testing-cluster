# This test verifies that log archival via zeek-archiver produces finalized logs
# in the installation's log directory. This does not wait for rotation/archival
# intervals to expire; instead, it relies on the fact that Zeek dispatches
# pending timers one last time upon shutdown.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Expand cluster so it periodically logs a message to a new test.log.
cat >>zeekscripts/local.zeek <<EOF
@load base/frameworks/cluster

@if ( Cluster::local_node_type() == Cluster::MANAGER || Cluster::local_node_type() == Cluster::LOGGER )

module Test;

export {
	# Create a new ID for our log stream
	redef enum Log::ID += { LOG };

	type Log: record {
		idx: count;
		msg: string;
	} &log;
}

global write_log: event();
global message_counter = 0;

event write_log()
	{
        Log::write(Test::LOG, [\$idx=++message_counter, \$msg="a log write"]);
        Log::flush(Test::LOG);
        schedule 0.2 secs { Test::write_log() };
        }

event zeek_init()
	{
	Log::create_stream(Test::LOG, [\$columns=Log]);
        schedule 0 secs { Test::write_log() };
	}

@endif
EOF

docker_compose_up

# This needs "ps" on the controller
controller_cmd "apt-get -q update && apt-get install -q -y --no-install-recommends procps"

# Deploy cluster
cat $FILES/config.ini | zeek_client deploy-config - \
    || fail "deploy-config did not succeed"

# Wait a bit until logs appear:
try_until controller_cmd "test -f /usr/local/zeek/var/lib/nodes/logger/test.log" \
    || fail "test.log never appeared"

# Verify there's a logger under the name we expect it to be, and stop it.
# We'll be able to do this via the client when we have an API for this.
controller_cmd "ps xc | grep -q zeek.logger"
controller_cmd 'kill $(ps xc | grep zeek.logger | awk "{ print \$1 }")'

# Wait a bit until rotated logs appear:
try_until controller_cmd "ls /usr/local/zeek/spool/log-queue/test* >/dev/null" \
    || fail "rotated test.log never appeared"

# Now stop the agent.
controller_cmd "ps xc | grep -q zeek.instance-1"
controller_cmd 'kill $(ps xc | grep zeek.instance-1 | awk "{ print \$1 }")'

# Wait a bit until archived logs appear in their YYYY-MM-DD datestamp folder:
try_until controller_cmd "ls /usr/local/zeek/logs/????-??-??/test*.gz >/dev/null" \
    || fail "archived test.log never appeared"
