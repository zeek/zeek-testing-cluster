FROM fedora:35
LABEL maintainer="Christian Kreibich <christian@corelight.com>"

# Packages for future dev usage (building plugins, running Zeek itself, etc)
ARG devrpms="cmake gcc gcc-c++ libpcap make"
# Packages for zkg
ARG zkgrpms="python3-GitPython python3-semantic_version"
# Packages for additional tooling
ARG toolrpms="bind-utils findutils procps-ng net-tools telnet psmisc"

ENV PATH "/usr/local/zeek/bin:${PATH}"
ENV PYTHONPATH "/usr/local/zeek/lib/zeek/python:${PYTHONPATH}"

RUN dnf install -y $devrpms $zkgrpms $toolrpms && dnf clean all

WORKDIR /usr/local/zeek/var/lib

COPY --from=zeektest-build /usr/local/zeek /usr/local/zeek
