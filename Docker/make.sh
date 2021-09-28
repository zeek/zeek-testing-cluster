#! /usr/bin/env bash
#
# This script creates or updates the Docker image corresponding to the current
# sources in the Zeek tree that has this tesuite hooked in. If it cannot find
# any source files newer than the creation date of the zeektest/zeek image, it
# does nothing. Otherwise it runs the build process, hopefully accelerated by a
# cached build tree and/or ccache.

# Various absolute paths
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
src_path=$(cd $dir/../../../.. && pwd)
ccache_path=$dir/ccache
build_path=$dir/build

# The name of the final Docker image. Note: this matches the image name used by
# the Docker image-building Github action (docker.yml).
docker_image=zeek:latest

# Whether we need to (re-)build the image
do_build=no

msg() {
    local red='\033[0;33m'
    local nc='\033[0m'
    printf "$red$@$nc\n"
}

# If the Docker image doesn't exist yet, we obviously need to build it.
docker images --format '{{.Repository}}:{{.Tag}}' | grep -q $docker_image || {
    msg "Docker image $docker_image unavailable, building..."
    do_build=yes
}

# If we're running in Github CI, a zeek:latest image must be available and we're
# going to use it as-is. (It will have just been built.) If the image is
# unavailable, something is wrong.
if [[ -n "$GITHUB_ACTION" ]]; then
     if [[ $do_build = yes ]]; then
         msg "Docker image ${docker_image} unavailable in Github Action workflow, aborting..."
         exit 1
     fi

     exit 0
fi

# If we have the image, we still might need to refresh it if the sources have
# changed.
if [[ $do_build = no ]]; then
    # Time in epoch seconds and fraction of the newest file in the sources. This
    # is a bit heuristic, but we exclude the default build tree this way.
    # This may include fractional seconds, which we drop.
    ts_src=$(cd $src_path && find . -path "./testing" -prune -o -path "./.git" -prune \
                                  -o -path "./build" -prune -o -name "*~" -prune \
                                  -o -name "#*" -prune -o -printf "%T@\n" \
                     | sort -rn | head -1 | cut -d. -f1)

    # For the image's last build date we use our own label (which records epoch
    # seconds) on the final stage in the zeek-prebuild -> zeekt-build ->
    # zeek:latest progression. This technically takes the start time, but the
    # final stage gets created after we've rebuilt zeektest/build with the
    # latest source tree. Double-check we get a number, since other strings
    # get returned if the label doesn't exist.
    ts_image=$(docker image inspect --format '{{ index .Config.Labels "com.corelight.buildtime" }}' $docker_image)
    if ! [[ $ts_image =~ ^[0-9]+$ ]]; then
        ts_image=0
    fi

    # The image might be new enough for the current source tree, but we may have
    # updated the Docker setup, so still need to rebuild. So also grab the
    # timestamps of the Docker setup:
    ts_docker=$(cd $dir && find . -path "./build" -prune -o -path "./ccache" -prune \
                                -o -name "*~" -prune -o -name "#*" -prune \
                                -o -printf "%T@\n" \
                        | sort -rn | head -1 | cut -d. -f1)

    if [[ $ts_src -gt $ts_image ]]; then
        msg "Docker image $docker_image older than sources ($ts_image/$ts_src), building..."
        do_build=yes
    elif [[ $ts_docker -gt $ts_image ]]; then
        msg "Docker image $docker_image older than Docker build contexts ($ts_image/$ts_docker), building..."
        do_build=yes
    fi
fi

if [[ $do_build = no ]]; then
    exit 0
fi

set -e

# This generates a "pre-build" image (zeek-prebuild) that has all the
# requirements for building Zeek. Since docker does not support build-time
# volume mounts, we use this pre-build image to then run a build command with
# volumes mounted; the result of this build gets committed to a new image
# (zeek-build). The final step is a multi-stage build continuation that grabs
# the installed build into a slimmer final image (zeek:latest).

docker build -t zeek-prebuild ./docker.prebuild

docker rm -f zeek-builder 2>/dev/null
docker run -it --name zeek-builder \
       -v "$src_path:/mnt/vol/src:z" \
       -v "$ccache_path:/mnt/vol/ccache:z" \
       -v "$build_path:/mnt/vol/build:z" zeek-prebuild
docker commit zeek-builder zeek-build
docker rm -f zeek-builder 2>/dev/null

# We add a timestamp label to the build to get a reliable build time. Both
# .Created and Metadata.LastTagTime have their problems: the former doesn't
# update when you'd expect it, the latter has nonstandard formatting.
docker build --label "com.corelight.buildtime=$(date +%s)" -t $docker_image ./docker.final

exit 0
