# This test verifies the connectivity establishment from a controller to two
# agents, as specified by a cluster configuration uploaded by the client.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output

. $SCRIPTS/docker-setup

docker_populate singlehost

# Configure the agents to listen only:
cat >>zeekscripts/agent-local.zeek <<EOF
redef Management::Agent::controller = [\$address="0.0.0.0", \$bound_port=0/unknown];
EOF

ZEEK_ENTRYPOINT=controller.zeek docker_compose_up

# Run two agents alongside the controller that wait for the controller to connect.

docker_exec controller mkdir /tmp/agent1 /tmp/agent2
docker_exec -d -w /tmp/agent1 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::name=instance-1 \
    Broker::default_port=10000/tcp
docker_exec -d -w /tmp/agent2 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::name=instance-2 \
    Management::Agent::default_port=2152/tcp \
    Broker::default_port=10001/tcp

zeek_client set-config - <<EOF
[instances]
instance-1 = 127.0.0.1:2151
instance-2 = 127.0.0.1:2152
EOF

zeek_client get-instances >output
