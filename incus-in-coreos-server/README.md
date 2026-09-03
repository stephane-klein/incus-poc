# Installing Incus on a CoreOS-powered server

Following the screen blocking issue encountered with IncusOS — it can't be shut down or put to sleep and stays on permanently, even with the lid closed, which is problematic for a headless server on a laptop (see the [Current Status](../incus-os/README.md) section) — I decided to install Incus on a [Fedora CoreOS](https://fedoraproject.org/coreos/), building on the work I did in this POC: [`atomic-os-playground`](https://github.com/stephane-klein/atomic-os-playground).

## Things to keep in mind about IncusOS versus CoreOS for running Incus

The biggest change concerns storage: IncusOS provides a local ZFS pool where QEMU VM disks are zvols (block devices) — better performance and consistent snapshots.

With CoreOS, ZFS is not available (CDDL license incompatible with the GPL kernel, and DKMS module incompatible with the immutable OSTree model), so I'd like to use a thin LVM pool:
the VMs would then run on block logical volumes with LVM snapshots, very close to the ZFS experience for QEMU performance.
What would actually be lost compared to ZFS: no compression, no checksum/integrity, and no zfs send replication.

## Todo

- [x] Prepare a Fedora CoreOS installation ISO image targeted at the Tuxedo (source of inspiration [`nuc-i7-gen11`](https://github.com/stephane-klein/homelab.sklein.xyz/tree/main/nuc-i7-gen11))
- [x] In the butane file: NetBird enrollment
- [x] In the butane file: disk partitioning (40 GB for CoreOS, 460 GB for the Incus thin LVM pool)
- [x] In the butane file: screen shutdown
- [x] Install and configure Incus (thin LVM pool, network access, client certificate)
- [x] In the butane file: Wake-on-LAN (S3 deep + wol-setup.service) to wake the server remotely
- [x] Install on the Tuxedo
- [ ] Verify CLI remote access

## Prerequisites

I install this prerequisites on my Fedora Workstation:

```
$ sudo dnf install \
    mise \
    butane \
    coreos-installer \
    whois
```

`whois` provides `mkpasswd`, used to generate the password hash for the butane file.

Then, to install the tools managed by Mise (see [`.mise.toml`](./.mise.toml)):

```
$ mise install
```

## Network configuration

Both interfaces stay connected at all times: Ethernet carries the default route (metric 100),
the Wi-Fi remains up as a live backup with a higher route metric (`route-metric=600`). When the
Ethernet link drops, the Wi-Fi default route takes over immediately — no dispatcher script involved.

- **Ethernet**: DHCP, NetworkManager default (route metric 100, preferred).
- **Wi-Fi**: SSID `stephane-klein.info_5G`, password from gopass
  (`gopass show -o homelab/wifi/stephane-klein.info_5G/password`), injected into
  [`wifi-home.nmconnection.j2`](./wifi-home.nmconnection.j2) at build time. The connection profile is
  baked into the installed system's `/etc/NetworkManager/system-connections` via the butane file
  (and provided to the live installer through `--network-keyfile`).
  `autoconnect=yes` keeps it active alongside Ethernet, and `ipv4.route-metric`/`ipv6.route-metric`
  are set to 600 so Ethernet stays the preferred default route.

## Waking the server from suspend (Wake-on-LAN)

The server can be suspended to save power and later woken remotely over Ethernet. Since the
[InfinityFlex 14 Gen1](https://notes.sklein.xyz/Tuxedo%20Infinity%20Flexible%2014%20Gen%201/) has
no built-in RJ45 port, Ethernet runs through a USB-attached Realtek *RTL8153* adapter (behind a
VL810 hub, on the Thunderbolt 4 controller). Waking it from suspend therefore relies on *USB remote
wakeup*, configured as follows in the [butane file](./coreos-custom-iso-config.bu.tmpl):

- **`kernel_arguments: should_exist: [mem_sleep_default=deep]`** — the server suspends to real S3
  (`deep`) rather than `s2idle` by default, which is what makes WoL reliable.
- **`wol-setup.service`** — a one-shot service runs [`/usr/local/sbin/wol-setup.sh`](./coreos-custom-iso-config.bu.tmpl)
  at every boot. The WoL flags are ephemeral (`ethtool` + `power/wakeup` in sysfs) and are lost on
  reboot, so the script re-arms:
  - `ethtool -s <iface> wol g` on the RTL8153 interface;
  - `power/wakeup = enabled` on the whole USB chain (adapter, hub, root hub).

A magic packet is a layer-2 broadcast: it does not cross subnets or the NetBird overlay. To wake the
server from outside the home LAN, relay it through an always-on host on the same network (e.g. the
`nuc-i7-gen11`), reachable over NetBird:

```sh
$ ssh stephane@nuc-i7-gen11.homelab.stephane-klein.info
$ python3 -c "import socket
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
mac = bytes.fromhex('4ce17347af2f')
s.sendto(b'\xff' * 6 + mac * 16, ('192.168.1.255', 9))"
```

Then suspend the server (it drops the session, so do it last):

```sh
$ ssh stephane@incus-server1.homelab.stephane-klein.info systemctl suspend
```

**Limitations observed**
- WoL only works on **AC power** (on battery the USB controller is not powered during suspend).
- Waking from a full **shutdown** (S5) over this USB adapter is not possible — only from suspend.
- `mem_sleep` falls back to `s2idle` when the kernel fails to freeze some workqueue within ~20 s
  (`Freezing remaining freezable tasks failed ... wq_busy=1`); WoL then still works from `s2idle`.

## Incus installation and configuration

Incus is installed and configured declaratively through the [butane file](./coreos-custom-iso-config.bu.tmpl):

- **Packages**: `incus lvm2 dnsmasq qemu-system-x86` are layered with rpm-ostree by the same
  one-shot service that installs NetBird.
- **Setup script**: on the second boot, the one-shot `incus-setup.service` runs
  [`/usr/local/sbin/incus-setup.sh`](./coreos-custom-iso-config.bu.tmpl), which:
  - adds the root idmap entry (`root:1000000:1000000000`) to `/etc/subuid` and `/etc/subgid`;
  - adds `stephane` to the `incus-admin` group (recreating a clean entry in `/etc/group`, since the
    group is provided by the `altfiles` NSS module from `/usr/lib/group`);
  - purges any leftover LVM volume group on the `incus-pool` partition from a previous install;
  - starts `incus.service` and applies [`/etc/incus-preseed.yaml`](./coreos-custom-iso-config.bu.tmpl).
- **Thin LVM pool**: the `incus-pool` partition (created at install) is used as the `default`
  storage pool with the `lvm` driver — Incus creates the volume group and the thin pool itself.
- **Network access**: Incus listens on `[::]:8443` (`core.https_address`) and a `incusbr0` managed
  bridge provides NAT to the instances.
- **Client certificate**: the client certificate and key are stored in gopass:
  - `homelab/incus-server1.homelab.stephane-klein.info/incus/client.crt`
  - `homelab/incus-server1.homelab.stephane-klein.info/incus/client.key`

To manage the server from a workstation (e.g. the Fedora laptop used for this POC):

```sh
$ mkdir -p ~/.config/incus
$ gopass show -o homelab/incus-server1.homelab.stephane-klein.info/incus/client.crt > ~/.config/incus/client.crt
$ gopass show -o homelab/incus-server1.homelab.stephane-klein.info/incus/client.key > ~/.config/incus/client.key
$ chmod 600 ~/.config/incus/client.key
$ incus remote add incus1 https://incus-server1.homelab.stephane-klein.info:8443 --accept-certificate
$ incus remote switch incus1
```
