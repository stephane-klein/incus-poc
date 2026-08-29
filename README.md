# Incus POC

I created this POC to test, learn how to use, and evaluate [Incus](https://github.com/lxc/incus/).

The driving motivation behind this POC is a likely future refactoring of [sklein-devbox](https://github.com/stephane-klein/sklein-devbox) to Incus.

## Roadmap

- [ ] Tests to run on Incus in LXC mode
  - [x] Launch a basic Fedora
  - [x] Test starting and stopping an LXC container
  - [ ] Create a custom Fedora image
    - [ ] Test pushing and pulling this image
  - [ ] Test that mounting a host directory into the LXC container works
  - [ ] Test installing and using Podman inside the LXC container
  - [ ] Test SSH access to the LXC container
  - [ ] Test cloning an LXC container
  - [ ] Create a script to measure
    - [ ] LXC container startup time
    - [ ] Disk space used by an LXC container
    - [ ] RAM usage of an LXC container
- [ ] Tests to run on Incus in QEMU mode
  - [x] Launch a basic Fedora
  - [x] Test starting and stopping a QEMU VM
  - [ ] Create a custom Fedora image
    - [ ] Test pushing and pulling this image
  - [ ] Test that mounting a host directory into the QEMU VM works
  - [ ] Test installing and using Podman inside the QEMU VM
  - [ ] Test SSH access to the QEMU VM
  - [ ] Test cloning a QEMU VM
  - [ ] Create a script to measure
    - [ ] QEMU VM startup time
    - [ ] Disk space used by a QEMU VM
    - [ ] RAM usage of a QEMU VM
- [ ] Test [IncusOS](https://linuxcontainers.org/incus-os/introduction/) by installing it on my [Tuxedo Infinity Flexible 14 Gen 1](https://notes.sklein.xyz/Tuxedo%20Infinity%20Flexible%2014%20Gen%201/) laptop, which I currently don't use and which could serve as a development server until RAM prices drop

## AI-Assisted Development

This project was developed using:

- [OpenCode](https://opencode.ai) CLI — coding assistant workflow (not vibe coding)
- Models: DeepSeek V4 Flash

## Installing and Configuring Incus on my Fedora Workstation

At the time of writing (August 29, 2026), the latest Incus release is [7.4](https://github.com/lxc/incus/releases/tag/v7.4.0), released on August 27, 2026.

As of today, Fedora only ships [6.23.3](https://packages.fedoraproject.org/pkgs/incus/incus/), which is 5 releases behind.
I found [someone else](https://discuss.linuxcontainers.org/t/incus-7-x-not-released-on-fedora/27173) looking for the latest Incus version for Fedora.

For now, and to avoid falling into [yak shaving](https://sklein.xyz/fr/garden/003-ne-tonds-pas-de-yaks/), I'll settle for 6.23.3 for this POC.

Here's how I installed and initialized Incus on my Fedora:

```sh
$ sudo dnf install -y incus
$ incus --version
6.23
$ sudo usermod -aG incus-admin stephane
$ echo "root:1000000:1000000000" | sudo tee -a /etc/subuid /etc/subgid
$ sudo systemctl enable --now incus.service
Created symlink '/etc/systemd/system/multi-user.target.wants/incus-startup.service' → '/usr/lib/systemd/system/incus-startup.service'.
Created symlink '/etc/systemd/system/sockets.target.wants/incus.socket' → '/usr/lib/systemd/system/incus.socket'.
$ systemctl status incus
● incus.service - Incus - Daemon
     Loaded: loaded (/usr/lib/systemd/system/incus.service; indirect; preset: disabled)
    Drop-In: /usr/lib/systemd/system/service.d
             └─10-timeout-abort.conf
     Active: active (running) since Sat 2026-08-29 18:38:31 CEST; 13s ago
 Invocation: 1dd8d5a438ba4d2eab1a135965086794
TriggeredBy: ● incus.socket
       Docs: man:incusd(1)
    Process: 164119 ExecStartPost=/usr/libexec/incus/incusd waitready --timeout=600 (code=exited, status=0/SUCCESS)
   Main PID: 164118 (incusd)
      Tasks: 28
     Memory: 101.8M (peak: 110M)
        CPU: 484ms
     CGroup: /system.slice/incus.service
             └─164118 /usr/libexec/incus/incusd --group incus-admin

août 29 18:38:30 t14s incusd[164118]: time="2026-08-29T18:38:30+02:00" level=error msg="Unable to parse system idmap" err="No map found for user"
août 29 18:38:30 t14s incusd[164118]: time="2026-08-29T18:38:30+02:00" level=warning msg="AppArmor support has been disabled because of lack of kernel support"
août 29 18:38:30 t14s incusd[164118]: time="2026-08-29T18:38:30+02:00" level=warning msg=" - AppArmor support has been disabled, Disabled because of lack of kernel support"
août 29 18:38:30 t14s qemu-system-x86_64[164192]: *HARK*  log.c:  92: core_log_lib_info: src version: 2.1.0
août 29 18:38:30 t14s qemu-system-x86_64[164192]: *HARK*  log.c:  94: core_log_lib_info: compiled with support for shutdown state
août 29 18:38:30 t14s qemu-system-x86_64[164192]: *HARK*  log.c:  97: core_log_lib_info: compiled with libndctl 63+
août 29 18:38:30 t14s qemu-system-x86_64[164196]: *HARK*  log.c:  92: core_log_lib_info: src version: 2.1.0
août 29 18:38:30 t14s qemu-system-x86_64[164196]: *HARK*  log.c:  94: core_log_lib_info: compiled with support for shutdown state
août 29 18:38:30 t14s qemu-system-x86_64[164196]: *HARK*  log.c:  97: core_log_lib_info: compiled with libndctl 63+
août 29 18:38:31 t14s systemd[1]: Started incus.service - Incus - Daemon.
```

Here's how I initialized Incus:

```sh
$ incus admin init
Would you like to use clustering? (yes/no) [default=no]: no
Voulez-vous configurer un nouveau pool de stockage ? (yes/no) [default=yes]: yes
Nom du nouveau pool de stockage [default=default]:
Nom du backend de stockage à utiliser (btrfs, dir, lvm) [default=btrfs]: btrfs
Would you like to create a new btrfs subvolume under /var/lib/incus? (yes/no) [default=yes]: yes
Voulez-vous créer un nouveau bridge réseau local ? (yes/no) [default=yes]: yes
Quel nom donner au nouveau bridge ? [default=incusbr0]:
Quelle adresse IPv4 utiliser ? (CIDR subnet notation, “auto” or “none”) [default=auto]:
Quelle adresse IPv6 utiliser ? (CIDR subnet notation, “auto” or “none”) [default=auto]:
Voulez-vous rendre le serveur accessible depuis le réseau ? (yes/no) [default=no]: yes
Adresses à associé à (sans inclure les ports) [default=all]:
Port auquel se lier [default=8443]:
Voulez-vous que les images mises en cache périmées soient mises à jour automatiquement ? (yes/no) [default=yes]:
Voulez-vous voir le fichier YAML de préconfiguration ? (yes/no) [default=no]: yes
config:
  core.https_address: '[::]:8443'
networks:
- config:
    ipv4.address: auto
    ipv6.address: auto
  description: ""
  name: incusbr0
  type: ""
  project: default
storage_pools:
- config:
    source: /var/lib/incus/storage-pools/default
  description: ""
  name: default
  driver: btrfs
storage_volumes: []
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: incusbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
  project: default
projects: []
certificates: []
cluster_groups: []
cluster: null
```

## List of available Fedora images

```sh
$ incus image list images: fedora/44
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
|            ALIAS            |  EMPREINTE   | PUBLIC |           DESCRIPTION            | ARCHITECTURE |      TYPE       |  TAILLE   |  DATE DE PUBLICATION  |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44 (3 de plus)       | 17d2b7249a1f | oui    | Fedora 44 amd64 (20260828_20:33) | x86_64       | VIRTUAL-MACHINE | 754.63MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44 (3 de plus)       | 794d87e8de86 | oui    | Fedora 44 amd64 (20260828_20:33) | x86_64       | CONTAINER       | 110.29MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/arm64 (1 de plus) | 3f1e393b552e | oui    | Fedora 44 arm64 (20260828_20:33) | aarch64      | VIRTUAL-MACHINE | 710.69MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/arm64 (1 de plus) | 29608e45e688 | oui    | Fedora 44 arm64 (20260828_20:33) | aarch64      | CONTAINER       | 104.12MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud (1 de plus) | 517e69071f1c | oui    | Fedora 44 amd64 (20260828_20:33) | x86_64       | CONTAINER       | 130.86MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud (1 de plus) | 195178d3444e | oui    | Fedora 44 amd64 (20260828_20:33) | x86_64       | VIRTUAL-MACHINE | 790.05MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud/arm64       | c12e54f7cf75 | oui    | Fedora 44 arm64 (20260828_20:33) | aarch64      | VIRTUAL-MACHINE | 745.96MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud/arm64       | ddec5bf0fb94 | oui    | Fedora 44 arm64 (20260828_20:33) | aarch64      | CONTAINER       | 123.79MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
```

## Launching my first LXC Fedora container

```sh
$ incus launch images:fedora/44 test1
Launching test1
```

I can see the `test1` instance is up and running:

```sh
$ incus list
+-------+---------+--------------------+------------------------------------------------+-----------+-------------+
| NAME | STATE | IPv4 | IPv6 | TYPE | SNAPSHOTS |
+-------+---------+--------------------+------------------------------------------------+-----------+-------------+
| test1 | RUNNING | 10.95.83.57 (eth0) | fd42:15b1:7fa2:bcd0:1266:6aff:fe30:1516 (eth0) | CONTAINER | 0           |
+-------+---------+--------------------+------------------------------------------------+-----------+-------------+
```

Let me look at the instance's details:

```sh
$ incus info test1
Nom : test1
Description :
État : RUNNING
Type : container
Architecture : x86_64
PID : 191282
Créé : 2026/08/29 19:13 CEST
Last Used: 2026/08/29 19:13 CEST
Started: 2026/08/29 19:13 CEST

Ressources :
  Processus : 16
  CPU utilisé :
    CPU utilisé (en secondes): 1
  Utilisation mémoire :
    Mémoire (courante): 87.99MiB
  Réseau utilisé :
    eth0:
      Type: broadcast
      State: UP
      Interface hôte: vethf0f4a29f
      MAC address: 10:66:6a:30:15:16
      MTU: 1500
      Octets reçus: 13.80kB
      Octets émis: 2.67kB
      Paquets reçus: 36
      Paquets émis: 27
      Adresses IP:
        inet:  10.95.83.57/24 (global)
        inet6: fd42:15b1:7fa2:bcd0:1266:6aff:fe30:1516/64 (global)
        inet6: fe80::1266:6aff:fe30:1516/64 (link)
    lo:
      Type: loopback
      State: UP
      MTU: 65536
      Octets reçus: 0B
      Octets émis: 0B
      Paquets reçus: 0
      Paquets émis: 0
      Adresses IP:
        inet:  127.0.0.1/8 (local)
        inet6: ::1/128 (local)
```

I'll open a terminal to get into the container:

```sh
$ incus exec test1 -- bash
[root@test1 ~]# dnf update -y
Updating and loading repositories:
 Fedora 44 openh264 (From Cisco) - x86_64                                                                                                                                                                                                           100% |   3.2 KiB/s |   5.3 KiB |  00m02s
 Fedora 44 - x86_64 - Updates                                                                                                                                                                                                                       100% |   3.8 MiB/s |  12.3 MiB |  00m03s
 Fedora 44 - x86_64                                                                                                                                                                                                                                 100% |  15.1 MiB/s |  36.7 MiB |  00m02s
Repositories loaded.
Nothing to do.
[root@test1 ~]# df -h
Filesystem                                             Size  Used Avail Use% Mounted on
/dev/mapper/luks-4da61083-2726-4c0f-9663-9755604be1b3  476G  379G   31G  93% /
none                                                   492K  4.0K  488K   1% /dev
devtmpfs                                                15G     0   15G   0% /dev/tty
efivarfs                                               248K   66K  178K  27% /sys/firmware/efi/efivars
tmpfs                                                  100K     0  100K   0% /dev/incus
tmpfs                                                  100K     0  100K   0% /dev/.incus-mounts
tmpfs                                                   16G     0   16G   0% /dev/shm
tmpfs                                                  6.1G  120K  6.1G   1% /run
tmpfs                                                   16G     0   16G   0% /tmp
[root@test1 ~]#
```

I'll stop the container:

```sh
$ incus stop test1
$ incus list
+-------+---------+------+------+-----------+-------------+
|  NOM  |  ÉTAT   | IPv4 | IPv6 |   TYPE    | INSTANTANÉS |
+-------+---------+------+------+-----------+-------------+
| test1 | STOPPED |      |      | CONTAINER | 0           |
+-------+---------+------+------+-----------+-------------+
```

I'll delete the container:

```sh
$ incus delete test1
$ incus list
+-----+------+------+------+------+-------------+
| NOM | ÉTAT | IPv4 | IPv6 | TYPE | INSTANTANÉS |
+-----+------+------+------+------+-------------+
```

## Launching my first Qemu Fedora VM

```sh
$ incus launch images:fedora/44 test2 --vm
$ incus list
+-------+---------+---------------------+--------------------------------------------------+-----------------+-------------+
| NAME  |  STATE  |        IPv4         |                       IPv6                       |      TYPE       | SNAPSHOTS  |
+-------+---------+---------------------+--------------------------------------------------+-----------------+-------------+
| test2 | RUNNING | 10.95.83.7 (enp5s0) | fd42:15b1:7fa2:bcd0:1266:6aff:fefc:1588 (enp5s0) | VIRTUAL-MACHINE | 0           |
+-------+---------+---------------------+--------------------------------------------------+-----------------+-------------+
$ incus exec test2 -- bash
[root@fedora ~]# dnf update -y
Updating and loading repositories:
 Fedora 44 openh264 (From Cisco) - x86_64                                                                                                                                                                                                           100% |   2.0 KiB/s |   5.3 KiB |  00m03s
 Fedora 44 - x86_64 - Updates                                                                                                                                                                                                                       100% |   2.7 MiB/s |  11.1 MiB |  00m04s
 Fedora 44 - x86_64                                                                                                                                                                                                                                 100% |  12.3 MiB/s |  39.9 MiB |  00m03s
Repositories loaded.
Nothing to do.
[root@fedora ~]# df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2       3.8G  1.3G  2.5G  35% /
devtmpfs        384M     0  384M   0% /dev
tmpfs           428M     0  428M   0% /dev/shm
efivarfs         56K   46K  5.7K  89% /sys/firmware/efi/efivars
tmpfs           171M  756K  171M   1% /run
tmpfs           428M     0  428M   0% /tmp
none            1.0M     0  1.0M   0% /run/credentials/systemd-journald.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-resolved.service
none            1.0M     0  1.0M   0% /run/credentials/systemd-networkd.service
/dev/sda1        99M  7.9M   91M   8% /boot/efi
tmpfs            50M   19M   32M  37% /run/incus_agent
none            1.0M     0  1.0M   0% /run/credentials/getty@tty1.service
none            1.0M     0  1.0M   0% /run/credentials/serial-getty@ttyS0.service
```

```sh
$ incus stop test2
$ incus list
+-------+---------+------+------+-----------------+-------------+
| NAME  |  STATE  | IPv4 | IPv6 |      TYPE       | SNAPSHOTS  |
+-------+---------+------+------+-----------------+-------------+
| test2 | STOPPED |      |      | VIRTUAL-MACHINE | 0           |
+-------+---------+------+------+-----------------+-------------+
$ incus start test2
$ incus list
+-------+---------+-------------------+------------------------------------------------+-----------------+-------------+
| NAME  |  STATE  |       IPv4        |                      IPv6                      |      TYPE       | SNAPSHOTS  |
+-------+---------+-------------------+------------------------------------------------+-----------------+-------------+
| test2 | RUNNING | 10.95.83.7 (eth0) | fd42:15b1:7fa2:bcd0:1266:6aff:fefc:1588 (eth0) | VIRTUAL-MACHINE | 0           |
+-------+---------+-------------------+------------------------------------------------+-----------------+-------------+
$ incus delete test2 --force
$ incus list
+-----+------+------+------+------+-------------+
| NOM | ÉTAT | IPv4 | IPv6 | TYPE | INSTANTANÉS |
+-----+------+------+------+------+-------------+
```

## Image management

```sh
$ incus image list
+-------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| ALIAS | FINGERPRINT | PUBLIC |           DESCRIPTION            | ARCHITECTURE |      TYPE       |   SIZE    |  PUBLICATION DATE   |
+-------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
|       | 17d2b7249a1f | no     | Fedora 44 amd64 (20260828_20:33) | x86_64       | VIRTUAL-MACHINE | 754.63MiB | 2026/08/29 19:43 CEST |
+-------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
|       | 794d87e8de86 | no     | Fedora 44 amd64 (20260828_20:33) | x86_64       | CONTAINER       | 110.29MiB | 2026/08/29 19:11 CEST |
+-------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
```

Deleting an image:

```
$ incus image delete 794d87e8de86
$ incus image list
+-------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| ALIAS | FINGERPRINT | PUBLIC |           DESCRIPTION            | ARCHITECTURE |      TYPE       |   SIZE    |  PUBLICATION DATE   |
+-------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
|       | 17d2b7249a1f | no     | Fedora 44 amd64 (20260828_20:33) | x86_64       | VIRTUAL-MACHINE | 754.63MiB | 2026/08/29 19:43 CEST |
+-------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
```
