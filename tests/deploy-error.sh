# This test verifies the output of a config deployment that fails to start one
# node.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.
wait_for_instances 1

# Let's break the logger:
docker_exec -i -- controller 'echo EEEK >>  $(zeek-config --script_dir)/base/frameworks/cluster/nodes/logger.zeek'

# Don't exit on error from now on since we want to examine exit codes.
set +e

# Deploy a small cluster and collect output. Normalize out the config UUID, and
# remove any stdout/stderr strings. We'd ideally want to keep (and normalize)
# those strings, but on rare occasion they're missing from the output due to
# races in the processing of the Supervisor's node/stem pipes. We preserve
# the raw output in output.zc for inspection.
cat $FILES/config.ini | zeek_client deploy-config - \
    | tee output.zc \
    | jq '.results.id = "xxx"' \
    | jq 'del(.results.nodes.logger.stderr)' \
    | jq 'del(.results.nodes.logger.stdout)' >output

[ ${PIPESTATUS[1]} -ne 0 ] || fail "deploy-config should have failed"
