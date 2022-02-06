@load policy/frameworks/management/controller
@load ./controller-local.zeek

redef Management::Controller::directory = "/var/log/zeek/mgmt";
