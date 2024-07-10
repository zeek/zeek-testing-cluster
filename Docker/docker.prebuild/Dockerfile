FROM debian:bullseye-slim
LABEL maintainer="Christian Kreibich <christian@corelight.com>"

# Configure system for build.
RUN apt-get -q update \
 && apt-get install -q -y --no-install-recommends \
     apt-utils \
     bind9 \
     bison \
     ccache \
     cmake \
     flex \
     g++ \
     gcc \
     git \
     libfl2 \
     libfl-dev \
     libmaxminddb-dev \
     libpcap-dev \
     libssl-dev \
     libz-dev \
     make \
     python3-minimal \
     python3.9-dev \
     swig \
     ninja-build \
     python3-pip \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

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

# The following volume mount results in a source tree not owned by the user
# running git on it. Prevent git from complaining about this:
RUN git config --global --add safe.directory "*"

VOLUME $VOL_SRC_DIR $VOL_BUILD_DIR $VOL_CCACHE_DIR

COPY ./build-zeek.sh $ZEEK_TOOLS_DIR

ENTRYPOINT ["/zeek/tools/build-zeek.sh"]
