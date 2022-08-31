# Content included here is only loaded in the Management controller.
@load policy/frameworks/management

# When the testsuite runs fully parallelized, delays start to go up.
# Give transactions more time to complete:
redef Management::Request::timeout_interval = 15 sec;
