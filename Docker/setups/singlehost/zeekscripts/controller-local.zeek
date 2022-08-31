# Content included here is only loaded in Management agents.
@load policy/frameworks/management

# When the testsuite runs fully parallelized, delays start to go up.
# Give transactions more time to complete:
redef Management::Request::timeout_interval = 25 sec;
