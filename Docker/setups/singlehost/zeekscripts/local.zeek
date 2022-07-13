# Anything added here will apply to all tests that use controller.zeek,
# agent.zeek, or controller-and-agent.zeek as entrypoint (see
# docker-compose.yml). Unless specifically required, tests needing to tweak
# local.zeek should append, not overwrite.

@if ( Cluster::is_enabled() )

# Have any cluster node log locally, for a trace not affected by peering with
# the logger(s).
redef Log::enable_local_logging = T;

@endif

# Test-specific customizations follow below.
