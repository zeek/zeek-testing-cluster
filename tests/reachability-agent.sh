# This test verifies that by default the agent listens globally on port
# 2151. Since running an agent also entails running a listening Supervisor, the
# test also verifies that it listens only locally, on its default port 9999.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost

# Only run agent, no controller:
ZEEK_ENTRYPOINT=agent.zeek docker_compose_up

# This needs "netstat":
controller_cmd "apt-get -q update && apt-get install -q -y --no-install-recommends net-tools"

# Wait a bit until the service is available from within the container.
try_until controller_cmd "exec 3<>/dev/tcp/127.0.0.1/2151" \
    || fail "agent never booted"

# The agent should be listening on 0.0.0.0:2151 now, while the Supervisor should
# be on 127.0.0.1:9999.
controller_cmd "netstat -tpln | grep zeek | awk '{ print \$4 }' | sort" >output
