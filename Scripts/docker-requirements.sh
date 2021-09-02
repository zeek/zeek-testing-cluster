#! /usr/bin/env bash
#
# Helper that verifies that we have a Docker setup suitable for our tests.
# This includes the availability of images that get build in the run-up to
# these tests, via the setup in the Docker directory.

docker_image=zeektest/zeek

command -v docker >/dev/null || {
    echo "docker command unavailable"
    exit 1
}

command -v docker-compose >/dev/null || {
    echo "docker-compose command unavailable"
    exit 1
}

# The zeektest/zeek image is the main driver for our docker-compose setup,
# so verify it exists:
docker images --format '{{.Repository}}' | grep -q $docker_image || {
    echo "Docker image $docker_image not found"
    exit 1
}

exit 0
