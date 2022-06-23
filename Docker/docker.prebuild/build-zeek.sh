#! /usr/bin/env bash

# Defaults for the Zeek sources and its build configuration. Git is a fallback;
# the idea is that the user provides local sources as a bind mount.
zeek_repo="https://github.com/zeek/zeek"
zeek_branch="master"
zeek_confflags="--build-type=Release --disable-zeekctl --ccache"

do_configure=no
do_buildwipe=no

set -e

msg() {
    local red='\033[0;33m'
    local nc='\033[0m'
    printf "$red$@$nc\n"
}

# Helper function to verify whether a given environment variable is defined.
check_env() {
    local name=$1
    local val=$(eval "echo \$$1")

    if [[ -z "$val" ]]; then
        echo "Invalid setup, need $name in environment"
        exit 1
    fi
}

help() {
    echo "Zeek builder for cluster testsuite"
    echo "USAGE: build-zeek.sh [options]"
    echo
    echo "  --configure          | Force (re-)configuration of the build"
    echo "  --confflags \"...\"  | Custom configure arguments to use ($zeek_confflags)"
    echo "  --wipe-build         | Wipe the build tree, if present from earlier run"
    echo
    echo "When not using a mount-provided source tree:"
    echo
    echo "  --zeek-repo URL      | Repo to clone from ($zeek_repo)"
    echo "  --zeek-branch BRANCH | Branch/tag/commit to build ($zeek_branch)"
    echo

    exit 0
}

while [ "$1" != "" ]; do
    case "$1" in
        "--configure")
            do_configure=yes
            shift
            ;;
        "--confflags")
            zeek_confflags="$2"
            shift 2
            ;;
        "--wipe-build")
            do_buildwipe=yes
            shift
            ;;
        "--zeek-repo")
            zeek_repo="$2"
            shift 2
            ;;
        "--zeek-branch")
            zeek_branch="$2"
            shift 2
            ;;
        *)
            help
            ;;
    esac
done

check_env ZEEK_SRC_DIR
check_env VOL_SRC_DIR
check_env VOL_BUILD_DIR
check_env VOL_CCACHE_DIR

# Establish the source tree -- it's either already there, provided as a mount by
# the user, or we grab it at the specified branch/tag/hash via git.

if [[ -f $VOL_SRC_DIR/configure ]]; then
    msg "*** Establishing source tree from volume mount"
    ln -s $VOL_SRC_DIR $ZEEK_SRC_DIR
else
    msg "*** Establishing source tree via git from $zeek_repo @ $zeek_branch"
    mkdir -p $ZEEK_SRC_DIR
    (
        cd $ZEEK_SRC_DIR
        git clone "$zeek_repo" .
        git checkout "$zeek_branch"
        git submodule sync --recursive
        git submodule update --recursive --init -j $(nproc)
    )
fi

# Wipe the build tree if requested. This gets rather close to an accidental rm
# -rf /, so add an extra check to run only inside a container.
if [[ -f /.dockerenv ]] && [[ $do_buildwipe = yes ]]; then
    rm -rf $VOL_BUILD_DIR/*
fi

# Configure the build
#
# If there isn't yet a build config, or the user explicitly asked for a reconfig,
# run configure.
if [[ ! -f "$VOL_BUILD_DIR/config.status" ]] || [[ $do_configure = yes ]]; then
    (
        cd $ZEEK_SRC_DIR
        msg "*** Configuring: --build-dir=$VOL_BUILD_DIR $zeek_confflags"
        ./configure --build-dir=$VOL_BUILD_DIR $zeek_confflags
    )
fi

# Build and install
(
    cores=$(nproc)
    msg "*** Building ($cores cores) & installing"
    cd $VOL_BUILD_DIR
    make -j $cores install
)
