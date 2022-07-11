# This test verifies the behavior of the client's get-config command around
# separate stage-config and subsequent deployment.

# @TEST-REQUIRES: $SCRIPTS/docker-requirements
# @TEST-EXEC: bash %INPUT
# @TEST-EXEC: btest-diff output-preupload-deployed.error
# @TEST-EXEC: btest-diff output-preupload-staged.error
# @TEST-EXEC: btest-diff output-predeploy-deployed.error
# @TEST-EXEC: btest-diff output-predeploy-staged.json
# @TEST-EXEC: btest-diff output.ini
# @TEST-EXEC: btest-diff output-postdeploy-deployed.json
# @TEST-EXEC: btest-diff output-postdeploy-staged.json
# @TEST-EXEC: btest-diff output-postredeploy-deployed.json

. $SCRIPTS/docker-setup
. $SCRIPTS/test-helpers

docker_populate singlehost
docker_compose_up

# The Zeek host now runs a controller named "controller" and an agent named
# "instance-1" that connects to it, with default settings.

zeek_client get-config >output-preupload-staged.error 2>&1 \
    && fail "zeek-client get-config without upload did not fail"

zeek_client get-config --deployed >output-preupload-deployed.error 2>&1 \
    && fail "zeek-client get-config --deployed without upload did not fail"

zeek_client stage-config - <<EOF
[instances]
instance-1

[manager]
instance = instance-1
port = 5000
role = manager

[logger-01]
instance = instance-1
port = 5001
role = logger

[worker-01]
instance = instance-1
role = worker
interface = eth0

[worker-02]
instance = instance-1
role = worker
interface = lo
EOF

zeek_client get-config --deployed >output-predeploy-deployed.error 2>&1 \
    && fail "zeek-client get-config --deployed after upload but without deployment did not fail"

# Remove the id field (containing the deployed configuration's UUID),
# so we can diff it.
zeek_client get-config --as-json \
    | tee output.zc.predeploy-staged.json \
    | jq 'del(.id)' >output-predeploy-staged.json

# The INI format does not include the ID field.
zeek_client get-config >output.ini

zeek_client deploy
wait_for_all_nodes_running || fail "nodes did not end up running"

zeek_client get-config --as-json --deployed \
    | tee output.zc.postdeploy-deployed.json \
    | jq 'del(.id)' >output-postdeploy-deployed.json
zeek_client get-config --as-json \
    | tee output.zc.postdeploy-staged.son \
    | jq 'del(.id)' >output-postdeploy-staged.json

# The above produced the output files locally, not in the Docker container.
cat output.ini | zeek_client deploy-config -
wait_for_all_nodes_running || fail "nodes did not end up running"

zeek_client get-config --as-json --deployed \
    | tee output.zc.postredeploy-deployed.json \
    | jq 'del(.id)' >output-postredeploy-deployed.json
