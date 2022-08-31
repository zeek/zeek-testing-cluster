@load policy/frameworks/management/controller
@load policy/frameworks/management/supervisor/config

redef Management::Controller::name = "controller";

# For testing it's helpful to see all node output on the console, because it
# then becomes visible via "docker logs".
redef Management::Supervisor::print_stdout = T;
redef Management::Supervisor::print_stderr = T;

# This gives tests a way to customize the controller ...
@if ( getenv("ZEEK_MANAGEMENT_NODE") == "CONTROLLER" )
@load ./controller-local.zeek
@endif

# ... and to customize globally.
@load ./local.zeek
