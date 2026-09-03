# IncusOS

This directory contains everything related to [IncusOS](https://linuxcontainers.org/incus-os/introduction/) in this POC.

The goal is to produce a custom IncusOS install image (`.img`) and write it to a USB stick, to install IncusOS on my [Tuxedo Infinity Flexible 14 Gen 1](https://notes.sklein.xyz/Tuxedo%20Infinity%20Flexible%2014%20Gen%201/) laptop.

## How it works

IncusOS has no traditional installer. Instead, the installation is *automated and unattended*: it relies on an *install seed*, a set of YAML files that configure the installation. The [flasher-tool](https://linuxcontainers.org/incus-os/docs/main/getting-started/download/) downloads a stock image from the Linux Containers CDN and injects a seed tar archive into it.

The seed files live in [`seed/`](./seed/):

| File | Role |
|:-----|:-----|
| [`applications.yaml`](./seed/applications.yaml) | Applications to install (`incus`) |
| [`install.yaml`](./seed/install.yaml) | Install options (`force_install`, target `nvme` bus) |
| [`incus.yaml.j2`](./seed/incus.yaml.j2) | Jinja template for the Incus seed (client certificate, HTTPS on port 443) |
| [`network.yaml`](./seed/network.yaml) | System hostname and domain (`incus1.homelab.stephane-klein.info`) |
| [`services.yaml.j2`](./seed/services.yaml.j2) | Jinja template for IncusOS services (NetBird enrollment) |

`incus.yaml`, `services.yaml` and `seed.tar` are generated files, not versioned.

## Prerequisites

- `incus` client installed and connected to a remote, to fetch the client certificate:
  ```
  $ incus remote get-client-certificate
  ```
- The tools below are installed via Mise (`mise install` in this directory):
  - `flasher-tool`
  - `minijinja-cli`

## Tasks

### Create the NetBird setup key

Creates a reusable NetBird setup key with unlimited usage via the [NetBird API](https://docs.netbird.io/api/resources/setup-keys), using the personal access token stored in gopass (`netbird/apikey`). The key is auto-assigned to the `homelab-servers` group and stored in gopass (`netbird/setup-keys/<name>`) so the seed can reference it.

```
$ mise run //incus-os/:create-netbird-setup-key
```

The key is consumed at first boot by the IncusOS NetBird service to enroll this machine as a peer.

### Render the seed

Generates `seed/incus.yaml` from the `incus.yaml.j2` template, injecting the client certificate from `incus remote get-client-certificate`, and `seed/services.yaml` from `services.yaml.j2`, injecting the NetBird setup key from gopass.

```
$ mise run //incus-os/:render-incus-seed
```

Then inspect the result:

```
$ cat incus-os/seed/incus.yaml
```

### Build the custom image

Renders the seed, builds the `seed.tar` archive and runs `flasher-tool -f img -s seed.tar`. The tool downloads the latest stable IncusOS release from the CDN and injects the seed into it.

The resulting image is written to `incus-os/IncusOS-custom.img`.

```
$ mise run //incus-os/:build-incusos-image
```

### Write the image to a USB stick

Detects the USB drives, asks which one to use, then writes `incus-os/IncusOS-custom.img` to it with `dd`.

```
$ mise run //incus-os/:write-to-usb
```

WARNING: this erases everything on the selected USB drive.

## Installation notes

The current [`install.yaml`](./seed/install.yaml) uses `target.bus: nvme`, so IncusOS will pick the NVMe drive as install target.

`force_install: true` means the target disk is formatted even if it already contains partitions. This is destructive.

The seed injects my client certificate (name `sklein`), so I can manage the installed server from my workstation right after install.

The seed also configures the [NetBird service](https://linuxcontainers.org/incus-os/docs/main/reference/services/netbird/) via [`services.yaml.j2`](./seed/services.yaml.j2): on first boot, IncusOS runs `netbird login --setup-key <key>` to enroll the machine into the `homelab-servers` NetBird group. The peer FQDN comes from [`network.yaml`](./seed/network.yaml) (`incus1.homelab.stephane-klein.info`). WARNING: seed data is kept in plain text on the system, and the setup key is reusable with unlimited usage (`type: reusable`, `usage_limit: 0`) until it expires, so anyone with access to the seed can enroll peers.

During installation, make sure to follow the SecureBoot configuration instructions: [Installing on a physical machine](https://linuxcontainers.org/incus-os/docs/main/getting-started/installation/physical/#configuring-the-bios).

Even with the `force_install: true` option, I couldn't get a reinstall to succeed.  
For reasons I don't understand, the IncusOS installer on a USB stick won't start once IncusOS is already installed on the NVMe drive. I can't tell whether I'm doing something wrong, or the machine boots straight from the internal disk as soon as it detects an existing IncusOS installation.

The only solution I found is to install [SystemRescue](https://www.system-rescue.org/) (`mise run :install-systemrescue`) on a second USB stick, boot into *SystemRescue* and delete every partition on the NVMe drive using [GParted](https://gparted.org/).  
After this cleanup, the IncusOS installer works again.

## Current status

IncusOS is now successfully installed on the Tuxedo laptop and is being used as a server.

There is currently one blocking issue: the screen cannot be turned off or put to sleep, so it stays lit permanently (even with the lid closed), which is problematic for a headless server running on a laptop.

This is tracked upstream in the issue [Implement a power management API](https://github.com/lxc/incus-os/issues/502).

In the meantime, to get more flexibility (notably the ability to turn the screen off), I plan to run Incus on a Fedora CoreOS system instead (see [`../incus-in-coreos-server/`](../incus-in-coreos-server/)).
