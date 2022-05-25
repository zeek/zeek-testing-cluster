@load policy/frameworks/management/controller

redef Management::Controller::name = "controller";

# This gives tests a way to overide settings:
@load ./controller-local.zeek
@load ./local.zeek
