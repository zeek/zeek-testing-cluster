FROM debian:bullseye-slim
LABEL maintainer="Christian Kreibich <christian@corelight.com>"

ENV PATH="/usr/local/zeek/bin:${PATH}"
ENV PYTHONPATH="/usr/local/zeek/lib/zeek/python"

# This installs the same set of packages we also provide in the official Docker image.
RUN apt-get -q update \
 && apt-get install -q -y --no-install-recommends \
     ca-certificates \
     git \
     libmaxminddb0 \
     libpython3.9 \
     libpcap0.8 \
     libssl1.1 \
     libz1 \
     python3-minimal \
     python3-git \
     python3-semantic-version \
     python3-websocket \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/zeek/var/lib

COPY --from=zeektest-build /usr/local/zeek /usr/local/zeek
