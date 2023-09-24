# EDK2 ArmVirtPkg + Systemd-Boot + Linux on QEMU

The goal of the project is to boot (and debug) QEMU with the following boot stack:

- UEFI (EDK2 ArmVirtPkg)
- Systemd-Boot
* Linux (efistub) + KVM

## Sync and setup
1. After cloning the repo, fetch the submodules:

    ```sh
    git submodule update --init --recursive
    ```

1. Install dependencies
* `docker` used for building EDK2
* `parted` and `mtools` used for QEMU filesystem
* `meson`, `ninja` and `python-pyelftools` for building Systemd-Boot

## Build
Run `build.sh` which generates the following build artifacts:

* EDK2 ArmVirtPkg: `QEMU_EFI.fd` and `QEMU_VARS.fd`
* Systemd-Boot: `systemd-bootaa64.efi`
* Linux+KVM: 

Above artifacts will be packaged into QEMU disks:

* QEMU pflash: `QEMU_{EFI,VARS}.raw` generated from `.fd` files
* QEMU NVMe drive: `disk.img` injected with Systemd-Boot and Linux+KVM

## Run
Edit `run.sh` and uncomment '-s -S' when starting QEMU to enable GDB breaking. Also uncomment remote GDB launching.
Run `run.sh` to start QEMU

## Debug
1. Since ASLR is disabled, save run logs: `./run.sh > runlogs.txt`
1. Parse run logs for symbol load address: `\grep add-symbol-file runlogs.txt > load-syms.gdb`
1. Run with GDB attach mode: `./run.sh debug`
1. In the GDB window, load the symbols: `source load-syms.gdb`


---

#### Repo Setup Details

1. Submodules setup as follows:

    ```sh
    git submodule add https://github.com/systemd/systemd.git systemd
    git submodule add https://github.com/tianocore/edk2.git edk2
    git submodule add --depth 1 https://github.com/torvalds/linux.git linux
    git submodule add https://github.com/landley/toybox.git toybox
    git submodule add https://github.com/MirBSD/mksh.git mksh
    git add systemd edk2 linux toybox mksh
    ```

1. Next statement

