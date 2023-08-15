# UEFI + Systemd-Boot on QEMU

## Setup
```
git submodule add https://github.com/systemd/systemd.git systemd
git add systemd
git submodule add https://github.com/tianocore/edk2.git edk2
git add edk2
```

## Systemd
Run `build_sdboot.sh` to generate systemd-bootaa64.efi

