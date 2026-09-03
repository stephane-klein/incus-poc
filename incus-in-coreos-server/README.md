# Installing Incus on a CoreOS-powered server

Following the screen blocking issue encountered with IncusOS — it can't be shut down or put to sleep and stays on permanently, even with the lid closed, which is problematic for a headless server on a laptop (see the [Current Status](../incus-os/README.md) section) — I decided to install Incus on a [Fedora CoreOS](https://fedoraproject.org/coreos/), building on the work I did in this POC: [`atomic-os-playground`](https://github.com/stephane-klein/atomic-os-playground).

## Things to keep in mind about IncusOS versus CoreOS for running Incus

The biggest change concerns storage: IncusOS provides a local ZFS pool where QEMU VM disks are zvols (block devices) — better performance and consistent snapshots.

With CoreOS, ZFS is not available (CDDL license incompatible with the GPL kernel, and DKMS module incompatible with the immutable OSTree model), so I'd like to use a thin LVM pool:
the VMs would then run on block logical volumes with LVM snapshots, very close to the ZFS experience for QEMU performance.
What would actually be lost compared to ZFS: no compression, no checksum/integrity, and no zfs send replication.

## Todo

- [ ] Prepare a Fedora CoreOS installation ISO image targeted at the Tuxedo (source of inspiration [`nuc-i7-gen11`](https://github.com/stephane-klein/homelab.sklein.xyz/tree/main/nuc-i7-gen11))
- [ ] In the butane file: disk partitioning (40 GB for CoreOS, 460 GB for the Incus thin LVM pool)
- [ ] In the butane file: NetBird enrollment and screen shutdown
- [ ] Install and configure Incus (thin LVM pool, network access, client certificate)
- [ ] Install on the Tuxedo
- [ ] Verify remote access (CLI and web UI) and the screen being off