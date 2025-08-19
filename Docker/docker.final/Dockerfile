FROM debian:13-slim

# This installs the same set of packages we also provide in the official Docker image.
RUN apt-get -q update \
 && apt-get install -q -y --no-install-recommends \
     ca-certificates \
     git \
     jq \
     libmaxminddb0 \
     libnode115 \
     libpcap0.8 \
     libpython3.13 \
     libssl3 \
     libuv1 \
     libz1 \
     libzmq5 \
     net-tools \
     procps \
     python3-git \
     python3-minimal \
     python3-semantic-version \
     python3-websocket \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/zeek/var/lib

COPY --from=zeektest-build /usr/local/zeek /usr/local/zeek

ENV PATH="/usr/local/zeek/bin:${PATH}"
ENV PYTHONPATH="/usr/local/zeek/lib/zeek/python"
