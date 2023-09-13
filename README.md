# EDK2 ArmVirtPkg + Systemd-Boot + Linux on QEMU

## Setup
One time init:
```
git submodule update --init --recursive
```

## EDK2
Run `docker_build.sh` to build EDK2 ArmVirtPkg

## Systemd
Run `build_sdboot.sh` to generate systemd-bootaa64.efi

## Linux

## QEMU + GDB
Edit `run.sh` and uncomment '-s -S' when starting QEMU to enable GDB breaking. Also uncomment remote GDB launching.
Run `run.sh` to start QEMU

---

#### Repo Setup Details
```
git submodule add https://github.com/systemd/systemd.git systemd
git add systemd
git submodule add https://github.com/tianocore/edk2.git edk2
git add edk2
```

