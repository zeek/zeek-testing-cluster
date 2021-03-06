# This test verifies the connectivity establishment from two agents to the
# controller, as specified by a cluster configuration uploaded by the client.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output.pre-config
# @TEST-EXEC: btest-diff output.post-config

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
ZEEK_ENTRYPOINT=controller.zeek docker_compose_up

# Run two agents alongside the controller that connect to it.
#
# Even agents connecting to the controller still need their own listening port,
# so data cluster nodes can peer with them. Since the Supervisor also listens,
# this means we require 4 ports in such a setup (which is an unusual one, since
# you wouldn't typically run multiple agents on a machine).
#
docker_exec controller mkdir /tmp/agent1 /tmp/agent2
docker_exec -d -w /tmp/agent1 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::name=instance-1 Broker::default_port=10000/tcp
docker_exec -d -w /tmp/agent2 -- controller zeek -j site/testing/agent.zeek \
    Management::Agent::default_port=2152/tcp \
    Management::Agent::name=instance-2 Broker::default_port=10001/tcp

# Give both agents time to connect to the controller:
wait_for_instances 2

# Canonicalize the agents' ephemeral ports for baselining:
zeek_client get-instances | tee output.zc.pre-config | jq '.[].port = "xxx"' >output.pre-config

# This should have no effect on the reported instances.
zeek_client deploy-config - <<EOF
[instances]
instance-1
instance-2
EOF

zeek_client get-instances | tee output.zc.post-config | jq '.[].port = "xxx"' >output.post-config
