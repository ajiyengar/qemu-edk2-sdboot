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
* Linux+KVM: `Image`

Above artifacts will be packaged into QEMU disks:

* QEMU pflash: `QEMU_{EFI,VARS}.raw` generated from `.fd` files
* QEMU NVMe drive: `qemu_disk.img`; GPT-formatted disk containing the following partitions:
  * _EFI System Partition_: Contains Systemd-Boot and related configuration files, and Linux+KVM image
  * _Root_: Linux Root filesystem

## Run
Run `run.sh` to start QEMU; this also starts GDB.

To disable GDB, edit `run.sh` and comment '-s -S' and remote GDB launching.

## Debug
Load symbols in GDB with the following command: `source load-syms.gdb`

If the memory layout changes, regenerate `load-symbols.gdb` as follows:

1. Since ASLR is disabled, save run logs: `./run.sh > runlogs.txt`
1. Parse run logs for symbol load address: `\grep add-symbol-file runlogs.txt > load-syms.gdb`
1. In the GDB window, load the symbols: `source load-syms.gdb`
1. Fix any source paths as needed: `set substitute-path /work .`

---

#### Miscellaneous Details

1. Submodules setup as below. No need to run these commands unless setting up a new repo.

    ```sh
    git submodule add https://github.com/systemd/systemd.git systemd
    git submodule add https://github.com/tianocore/edk2.git edk2
    git submodule add --depth 1 https://github.com/torvalds/linux.git linux
    git submodule add https://github.com/landley/toybox.git toybox
    git submodule add https://github.com/MirBSD/mksh.git mksh
    git add systemd edk2 linux toybox mksh
    ```

1. `dd` seek and skip can be easy to confuse:

   _#Skip 20 sectors in **infile**, then copy 10 sectors from infile to outfile:_

     ```sh
     dd if=infile of=outfile bs=512 count=10 skip=20
     ```

   _#Skip 20 sectors in **outfile**, then copy 10 sectors from infile to outfile:_

     ```sh
     dd if=infile of=outfile bs=512 count=10 seek=20
     ```

1. Interesting breakpoints:

  * `b PrePeiCoreEntryPoint.iiii:_ModuleEntryPoint` -- EDK2 PEI stage entry point
  * `b DxeHandoff.c:HandOffToDxeCore` -- Handoff between PEI and DXE stages
  * `b DxeCoreEntryPoint.c:_ModuleEntryPoint` -- EDK2 DXE stage entry point
    * End of `DxeMain` has the jump from DXE to BDS stage
  * `b BdsEntry.c:BdsEntry` -- EDK2 BDS stage entry point
  * `b boot.c:efi_main` -- Systemd-Boot entry point
    * Inside `UefiBootManagerLib/BmBoot.c:EfiBootManagerBoot` is the jump from BDS to Systemd-Boot
  * `b efi-stub-entry.c:efi_pe_entry` -- EFISTUB entry point
    * Inside `boot.c:image_start` is the jump from Systemd-Boot to EFISTUB


