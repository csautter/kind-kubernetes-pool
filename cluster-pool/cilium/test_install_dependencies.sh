#!/usr/bin/env bash

set -e

docker run --rm -v $(pwd):/workdir ubuntu:24.04 bash -c "cd /workdir && ls -la && bash install_dependencies.sh"