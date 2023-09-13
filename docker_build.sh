#!/usr/bin/env bash

set -e

###############
# Docker Build
###############
docker pull ghcr.io/tianocore/containers/ubuntu-22-dev:latest
docker run -it -v /mnt/data/dockerhome:/home -v .:/work \
  -e EDK2_DOCKER_USER_HOME=/home -w /work \
  ghcr.io/tianocore/containers/ubuntu-22-dev:latest \
  /bin/bash build_armvirt.sh
