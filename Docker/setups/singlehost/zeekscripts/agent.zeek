@load policy/frameworks/management/agent
@load policy/frameworks/management/supervisor/config

redef Management::Agent::name = "instance-1";

# For testing it's helpful to see all node output on the console, because it
# becomes visible via "docker logs".
redef Management::Supervisor::print_stdout = T;
redef Management::Supervisor::print_stderr = T;

# This gives tests a way to overide settings:
@load ./agent-local.zeek
@load ./local.zeek
