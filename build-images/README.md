# build-images

Custom Fedora images for Incus (container + VM), built with
[distrobuilder](https://linuxcontainers.org/distrobuilder/docs/latest/) from
`fedora.yaml`.

Build and import them with:

```sh
$ mise run //build-images:build-lxc
$ mise run //build-images:build-vm
```

## Publish to Scaleway S3 (simple streams)

### I discovered the simple streams format — here is what I understood

I discovered the **simple streams format** while reading the [Incus
documentation](https://linuxcontainers.org/incus/docs/main/howto/images_remote/#list-configured-remotes)
to figure out how to distribute custom images without running a dedicated image
server.

In a nutshell, it's a **normalized file and directory layout** served over plain
HTTP/HTTPS — no server-side logic, no database, just static files:

- `streams/v1/index.json` — entry point, announces the available metadata streams
- `streams/v1/images.json` — the catalogue: products → versions → items, with
  fingerprints and aliases
- `images/<fingerprint>.<ext>` — the image files themselves

The format was designed by **Canonical** (initially for Ubuntu cloud images) and
is used mostly within the Canonical ecosystem (Ubuntu Cloud Images, MAAS, Juju,
cloud-init), as well as by LXD/Incus and `images.linuxcontainers.org`.

Generate the simplestreams index and publish the built LXC + VM images:

```sh
$ mise run //build-images:upload-images
```

This regenerates the index with `incus-simplestreams add` and mirrors the
`streams/v1/` + `images/` tree to the bucket with `rclone sync --s3-acl
public-read` (only the latest build of each image is kept).

## Pull images from the public HTTP server exposed by Scaleway S3

Then consume the images from any Incus server:

```sh
$ incus remote add sklein https://incus-images.s3.fr-par.scw.cloud --protocol=simplestreams
$ incus remote list
+-----------------+------------------------------------------+---------------+-------------------------+--------+----------+--------+
|       NOM       |                   URL                    |   PROTOCOLE   | TYPE D'AUTHENTIFICATION | PUBLIC | STATIQUE | GLOBAL |
+-----------------+------------------------------------------+---------------+-------------------------+--------+----------+--------+
| images          | https://images.linuxcontainers.org       | simplestreams | none                    | OUI    | NON      | NON    |
+-----------------+------------------------------------------+---------------+-------------------------+--------+----------+--------+
| local (courant) | unix://                                  | incus         | file access             | NON    | OUI      | NON    |
+-----------------+------------------------------------------+---------------+-------------------------+--------+----------+--------+
| sklein          | https://incus-images.s3.fr-par.scw.cloud | simplestreams | none                    | OUI    | NON      | NON    |
+-----------------+------------------------------------------+---------------+-------------------------+--------+----------+--------+
$ incus image list sklein:
+-----------------------------+--------------+--------+---------------------------------+--------------+-----------------+-----------+-----------------------+
|            ALIAS            |  EMPREINTE   | PUBLIC |           DESCRIPTION           | ARCHITECTURE |      TYPE       |  TAILLE   |  DATE DE PUBLICATION  |
+-----------------------------+--------------+--------+---------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud (3 de plus) | 6d29b1a7ed4d | oui    | fedora 44 x86_64 (202609021738) | x86_64       | CONTAINER       | 217.88MiB | 2026/09/02 02:00 CEST |
+-----------------------------+--------------+--------+---------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud (3 de plus) | 333847a78467 | oui    | fedora 44 x86_64 (202609021749) | x86_64       | VIRTUAL-MACHINE | 931.22MiB | 2026/09/02 02:00 CEST |
+-----------------------------+--------------+--------+---------------------------------+--------------+-----------------+-----------+-----------------------+
$ incus image info sklein:6d29b1a7ed4d
Empreinte : 6d29b1a7ed4d72205f3c98e47540603c3f0aa846d96bcb3b781edc6bcc6703dc
Size: 217.88MiB
Architecture : x86_64
Type : container
Public : oui
Horodatage :
    Créé : 2026/09/02 02:00 CEST
    Publié : 2026/09/02 02:00 CEST
    Expire : 1970/01/01 01:00 CET
    Dernière utilisation : jamais
Propriétés :
    architecture: x86_64
    serial: 202609021738
    variant: cloud
    os: fedora
    release: 44
    description: fedora 44 x86_64 (202609021738)
    type: squashfs
Alias :
    - fedora/44/cloud
    - fedora/44/cloud/x86_64
    - fedora-44-sklein
    - fedora-44-sklein/x86_64
En cache : non
Mise à jour auto : désactivé
Profils : []
$ incus launch sklein:fedora-44-sklein my-instance
```

## Don't forget `image.variant: cloud` in `fedora.yaml`

I hit a trap with this POC: forgetting `image.variant: cloud` leaves the default
`"default"` filter active, so every `files:`, `packages:` and `actions:` block
tagged `variants: [cloud]` is skipped — cloud-init is never installed and the
cloud-init user-data (e.g. the SSH keys in `../test5-custom-fedora-image.yaml`)
will not work. The rule: `image.variant: cloud` in the `image:` section must
match the `variants: [cloud]` filters for them to apply. See the
[Image](https://linuxcontainers.org/distrobuilder/docs/latest/reference/image/)
and
[Filters](https://linuxcontainers.org/distrobuilder/docs/latest/reference/filters/)
references.

## NetBird

The images ship the [NetBird](https://netbird.io/) client, so an instance can be
enrolled into a NetBird network on first boot.

### How it is built

- `fedora.yaml` adds the official NetBird `yum` repository
  (`packages.repositories`) and installs the `netbird` package with
  `--setopt=tsflags=noscripts` (`packages.sets[].flags`). The RPM `%post`
  scriptlet (`netbird service install` / `service start`) would fail inside the
  distrobuilder build chroot, which has no active systemd, so it is skipped.
  The service is therefore installed but *not* started or enabled in the image.
- A helper script is shipped at `/usr/local/sbin/enroll-netbird.sh`. It takes the
  path of a file holding the setup key as `$1` and is a no-op when that file is
  empty or missing. Otherwise it installs/starts the `netbird` daemon at runtime,
  waits for its socket, then runs `netbird up --daemon-addr ... --setup-key-file "$1"`.
  The key file is removed on exit (also on failure). Enrollment failure is a hard
  error (blocking cloud-init).

This follows the NetBird-recommended flow for unattended deployments:
[Bootstrap peers via config file](https://docs.netbird.io/manage/peers/bootstrap-via-config-file)
(keep the setup key out of the config and pass it at runtime via
`--setup-key-file` / `NB_SETUP_KEY`).

### Enrolling an instance via cloud-init

Pass the setup key in the instance's `cloud-init.user-data`. The key is written
to a temporary file (to avoid it showing up in the process list) then handed to
the script, which removes it afterwards:

```yaml
config:
  cloud-init.user-data: |
    #cloud-config
    write_files:
      - path: /tmp/netbird-setup-key
        content: <SETUP_KEY>
        permissions: "0600"
    runcmd:
      - [bash, /usr/local/sbin/enroll-netbird.sh, /tmp/netbird-setup-key]
```

> [!warning]
> The setup key sits in plain text in the instance configuration, and the
> NetBird setup key is reusable, so anyone who can read the instance config can
> enroll peers. Keep the config access restricted.

### NetBird Cloud

This POC uses NetBird Cloud (the default management endpoint of `netbird up`);
no `--management-url` is set.

### Container (LXC) requirements

An unprivileged container already has all capabilities enabled within its user
namespace, including `CAP_NET_ADMIN` — so NetBird/WireGuard can create the
interface without extra `raw.lxc` or `security.privileged` (this was my initial
mistake: overriding `lxc.cap.drop` via `raw.lxc` is both invalid LXC syntax and
managed by Incus itself).

For the LXC instance, only `security.nesting: "true"` is set (see
`../test5-custom-fedora-image.yaml.j2`):

```yaml
config:
  security.nesting: "true"
```

Also make sure the `wireguard` kernel module is loaded on the host
(`modprobe wireguard`) — NetBird uses the kernel WireGuard implementation, not
`/dev/net/tun`.

If enrollment still fails for the LXC container, falling back to
`security.privileged: "true"` is the alternative (less isolated). QEMU VMs do
not need this, as there is no user namespace.
