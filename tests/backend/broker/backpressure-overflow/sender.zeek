# The sender fires batches of one-way ping events to a receiver to make it
# consume buffer space. An included epoch counter tracks how often we'receiving
# backpressure-induced unpeerings. While this is happening, the sender also
# receives ping events (of a different type) from the manager, which it echoes
# back to it. This verifies that the sender itself does not lock up. Messaging
# to stdout provides status updates.

# Where to send the ping, controlled by the SENDER environment variable. We will
# either generate load worker->proxy, or proxy->worker.
global ping_topic = getenv("SENDER") == "proxy" ? Cluster::worker_topic : Cluster::proxy_topic;

global padding: string = string_fill(256, "1234567890"); # To eat buffer space
global ping_ival: interval = 0.01sec; # Rapdid, to eat up space quickly

# Number of pings to send in one batch. This triggers overflow much more
# quickly, since buffer limits operate on message granularity.
global ping_batch = 20;

global epoch = 0; # Epochs increase with every backpressure-triggered de-peering
global counter = 0; # A ping counter.

# A ping from manager to worker that the worker echoes back, to verify
# liveness of that peering. This should always keep chugging -- if not, it means
# the worker's I/O troubles propagate to the manager: global lockup.
global manager_ping: event(ctr: count);

# A one-way ping to our target. It consumes space via a padding string to speed
# up backpressure. The epoch increases every time a backpressure unpeering
# occurs in the target.
global ping: event(epoch: count, ctr: count, padding: string);

event Broker::peer_removed(endpoint: Broker::EndpointInfo, msg: string)
	{
	if ( "caf::sec::backpressure_overflow" !in msg )
		return;

	# This is our signal that the proxy is gone. We keep sending pings
	# and bump up the epoch to distinguish before/after the de-peering.

	++epoch;
	print fmt("%s UNPEERED, epoch now %d", current_time(), epoch);
	}

# This comes from the manager. We echo it back.
event manager_ping(ctr: count) &is_used
	{
	Broker::publish(Cluster::manager_topic, manager_ping, ctr);
	}

event driver()
	{
	local i = 0;
	while ( ++i < ping_batch )
		Broker::publish(ping_topic, ping, epoch, ++counter, padding);

	schedule ping_ival { driver() };
	}

event zeek_init() {
	schedule ping_ival { driver() };
}
