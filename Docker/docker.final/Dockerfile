FROM fedora:35
LABEL maintainer="Christian Kreibich <christian@corelight.com>"

# Packages for future dev usage (building plugins, running Zeek itself, etc)
ARG devrpms="cmake gcc gcc-c++ libpcap make"
# Packages for zkg
ARG zkgrpms="python3-GitPython python3-semantic_version"
# Packages for additional tooling
ARG toolrpms="bind-utils findutils procps-ng net-tools telnet psmisc"

ENV PATH "/usr/local/zeek/bin:${PATH}"

RUN dnf install -y $devrpms $zkgrpms $toolrpms && dnf clean all
RUN mkdir -p /var/log/zeek/mgmt /var/log/zeek/cluster

WORKDIR /var/log/zeek

COPY --from=zeektest-build /usr/local/zeek /usr/local/zeek
