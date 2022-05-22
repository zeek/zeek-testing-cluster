@load policy/frameworks/management/agent

redef Management::Agent::controller = [$address="controller", $bound_port=2150/tcp];
