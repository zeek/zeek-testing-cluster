FROM fedora:34
LABEL maintainer="Christian Kreibich <christian@corelight.com>"

# Requirements for the Zeek build
RUN dnf install -y bison ccache cmake gcc gcc-c++ make python3 flex git \
    libpcap-devel openssl-devel python3-devel swig zlib-devel

# Zeek-related locations in our image
ENV ZEEK_DIR=/zeek
ENV ZEEK_SRC_DIR=$ZEEK_DIR/src
ENV ZEEK_TOOLS_DIR=$ZEEK_DIR/tools

# A mountpoint for Zeek's source tree
ENV VOL_SRC_DIR=/mnt/vol/src
# A mountpoint for the build tree
ENV VOL_BUILD_DIR=/mnt/vol/build
# A mountpoint for ccache's cache data
ENV VOL_CCACHE_DIR=/mnt/vol/ccache
# Direct ccache to store its data in a volume
ENV CCACHE_DIR=/mnt/vol/ccache

RUN mkdir -p $ZEEK_TOOLS_DIR

VOLUME $VOL_SRC_DIR $VOL_BUILD_DIR $VOL_CCACHE_DIR

COPY ./build-zeek.sh $ZEEK_TOOLS_DIR

ENTRYPOINT ["/zeek/tools/build-zeek.sh"]
