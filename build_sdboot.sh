#!/bin/sh

#Deps: pacman -S meson ninja pyelftools gperf

set -e

meson setup --default-library static --prefer-static --cross-file meson_aarch64.txt systemd/build_aarch64/ systemd/
ninja -C systemd/build_aarch64/ systemd-boot
