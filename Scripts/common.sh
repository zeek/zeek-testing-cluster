# This is sourced from various tests directly,

testname=$(echo "$TEST_NAME" | sed 's/[^a-zA-Z0-9]/_/g')

cleanup() {
    docker-compose -p $testname -f $DOCKER/docker-compose.yml down -t 1
}

trap cleanup EXIT

docker_run() {
    local container="$1"
    local command="$2"
    docker exec ${testname}_${container}_1 bash -l -c "$command"
}

docker-compose -p $testname -f $DOCKER/docker-compose.yml up -d
