#!/usr/bin/env bash

set -e

###############
# Patch
###############
set +e
patch --binary -d edk2 -p1 -N -i \
  ../0001-edk2-enable-debug-O0.patch -r-
[[ $? -gt 1 ]] && \
  { echo "ERR: EDK2 patch failed"; exit 0; }
set -e

###############
# Docker Build
###############
docker pull ghcr.io/tianocore/containers/ubuntu-22-dev:latest
docker run -it -v /mnt/data/dockerhome:/home -v .:/work \
  -e EDK2_DOCKER_USER_HOME=/home -w /work \
  ghcr.io/tianocore/containers/ubuntu-22-dev:latest \
  /bin/bash docker_build_armvirt.sh
