# The receiver of ping events locks itself up in the script layer after
# receiving a handful of pings from the sender. It does this lockup by sitting
# in a tight loop on sleeps, checking for the presence of a file after each
# sleep to break the loop, and hopefully resume receiving pings from the
# sender. Messaging to stdout provides status updates.

global unwedge_file = "/tmp/zeek-unwedge"; # Presence of this file un-wedges the node.
global epoch_rx = 0;
global pings_rx = 0;
global wedgie: event();
global ping: event(epoch: count, ctr: count, padding: string);

event wedgie() {
	# Loop forever, but check occasionally whether the unwedge_file exists,
	# and bail if so. Meanwhile pings coming in from the sender pile up.
	print fmt("%s WEDGING", current_time());

	while ( T )
		{
		sleep(1sec);

		if (file_size(unwedge_file) >= 0.0) {
			print fmt("%s UNWEDGED", current_time());
			return;
		}
	}
}

event ping(epoch: count, ctr: count, padding: string) &is_used {
	if ( epoch == 0 )
		{
		# Lock up the script layer after we've received a few pings.
		# The pings continue to arrive but no longer make it to this
		# event handler, since we're busy-spinning above.
		if ( ++pings_rx == 10 )
			event wedgie();
		}

	if ( epoch == 1 && epoch_rx == 0 )
		{
		# We're starting to see pings again post-wedgie. W00t.
		print fmt("%s RECOVERED at ping %d", current_time(), ctr);
		}

	epoch_rx = epoch;
}
