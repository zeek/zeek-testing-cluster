@load policy/frameworks/management/agent

redef Management::Agent::name = "instance-1";

# This gives tests a way to overide settings:
@load ./agent-local.zeek
@load ./local.zeek
