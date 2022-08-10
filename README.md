Zeek Cluster Management Framework Testsuite
===========================================

This repository contains an external testsuite for Zeek, focusing on the
Management framework and cluster operations. External testsuites are ones that
don't ship with Zeek by default.

Usage
-----

To run the testsuite:

- Ensure you have a working Docker and `docker-compose` toolchain on your system.

- Clone this repository in the `testing/external` directory of the Zeek source
  tree:

      $ cd zeek
      $ cd testing/external
      $ git clone https://github.com/zeek/zeek-testing-cluster

  As with other external testsuites, the `commit-hash.zeek-testing-cluster` file
  in that directory indicates the version of the testsuite to use with your
  current Zeek sources. In recent Zeek versions, you can say `make sync-repos`
  in `testing/external` to move any present external testsuites to the versions
  matching your source tree:

      $ make sync-repos

  With older Zeeks, manually check out the git commit hash in
  `commit-hash.zeek-testing-cluster`:

      $ cd zeek-testing-cluster && git checkout $(cat ../commit-hash.zeek-testing-cluster)

- Say `make`, either in `testing/external` to run all external testsuites, or in
  `testing/external/zeek-testing-cluster` to just run this testsuite.

Architecture
------------

The testsuite relies heavily on Docker images and `docker-compose` to create
isolated environments in which to run the tests. The test driver is
[btest](https://github.com/zeek/btest), as in Zeek's other testsuites. The tests
reside in the `tests` directory.

Each test launches its test environment via `docker-compose`, runs a test, then
tears down the environment. Test naming propagates into the Docker environments,
to allow parallelized test execution via `btest -j`.

For example, if you run the `deploy-minimal` test via `btest
./tests/deploy-minimal.sh`, you'll see two Docker images as part of the
corresponding `docker-compose` environment while the test is running:

    $ docker ps
    CONTAINER ID   IMAGE             COMMAND                  CREATED         STATUS         PORTS                                         NAMES
    06de35b5b3ce   zeektest:latest   "/usr/local/zeek/bin…"   6 seconds ago   Up 2 seconds   0.0.0.0:49314->2150/tcp, :::49314->2150/tcp   tests_deploy_minimal__controller_1
    92df9aeba5ed   zeektest:latest   "bash"                   6 seconds ago   Up 2 seconds                                                 tests_deploy_minimal__client_1

Docker image
------------

The testsuite requires a single Docker image called `zeektest:latest`. You have
two options for providing this image: you can let the testsuite build it for you
from the local Zeek sources, or you can grab a recent [official Zeek Docker
image](https://hub.docker.com/u/zeekurity) and tag it (e.g. via `docker tag
zeek:latest zeektest:latest`). Since you normally want to run the testsuite on a
freshly built Zeek as part of ongoing development, we recommend the former
approach, and it's the one used automatically when you run the testsuite inside
a Zeek source tree. Grabbing a pre-existing Docker image risks running the
testsuite against a mismatched Zeek build, since the association provided by the
`commit-hash.zeek-testing-cluster` file is lost. (So why provide it? Zeek's own
CI setup already builds a Docker image, and the testsuite then uses this locally
pre-existing image.)

Since a full Zeek build for every testsuite run would take too long, the Docker
image build setup provided by the testsuite keeps the `build` directory outside
of the image, and additionally uses its own `ccache` when supported. This means
that after an initial full build the build runs quickly and incrementally, or
can be skipped entirely. For the full details of how the image gets updated, see
the `Docker/make.sh` script.

Make targets
------------

Running `make` in the testsuite's toplevel directory does two things:

- The `docker` target ensures the `zeektest:latest` image is available and up to
  date. You can run `make docker` explicitly if you just want to update the image.

- The `test-verbose` target then runs the tests themselves.

btest environments
------------------

For troubleshooting it can be helpful to keep a test's Docker images running
after the test finishes. The testsuite's `btest.cfg` provides two alternatives
to facilitate this:

- `btest -a debug` keeps all containers running.

- `btest -a debug-failures` keeps the containers of any failing tests running.
