#!/usr/bin/env bash

#Deps: meson ninja pyelftools

set -e

#Cross compile systemd-boot for aarch64
meson setup --default-library static --prefer-static --cross-file meson_aarch64.txt systemd/build_aarch64/ systemd/
ninja -C systemd/build_aarch64/ systemd-boot
