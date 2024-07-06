@load policy/frameworks/management/controller

# Disable metrics port assignment by default to reduce baseline noise.
redef Management::Controller::auto_assign_metrics_ports = F;

# This gives tests a way to overide settings:
@load ./controller-local.zeek
@load ./local.zeek
