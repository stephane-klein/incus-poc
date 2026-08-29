# Incus POC

I created this POC to test, learn how to use, and evaluate [Incus](https://github.com/lxc/incus/).

The driving motivation behind this POC is a likely future refactoring of [sklein-devbox](https://github.com/stephane-klein/sklein-devbox) to Incus.

## Roadmap

- [ ] Tests to run on Incus in LXC mode
  - [x] Launch a basic Fedora
  - [x] Test starting and stopping an LXC container
  - [x] Launch an LXC container with [incus-apply](https://incus-apply.abiosoft.com/)
  - [x] Test that mounting a host directory into the LXC container works
  - [ ] Test SSH access to the LXC container
  - [ ] Create a custom Fedora image with [distrobuilder](https://github.com/lxc/distrobuilder)
    - [ ] Test pushing and pulling this image
  - [ ] Test installing and using Podman inside the LXC container
  - [ ] Test cloning an LXC container
  - [ ] Create a script to measure
    - [ ] LXC container startup time
    - [x] Disk space used by an LXC container
    - [ ] RAM usage of an LXC container
- [ ] Tests to run on Incus in QEMU mode
  - [x] Launch a basic Fedora
  - [x] Test starting and stopping a QEMU VM
  - [x] Launch a QEMU VM with [incus-apply](https://incus-apply.abiosoft.com/)
  - [x] Test that mounting a host directory into the QEMU VM works
  - [ ] Test SSH access to the QEMU VM
  - [ ] Create a custom Fedora image with [distrobuilder](https://github.com/lxc/distrobuilder)
    - [ ] Test pushing and pulling this image
  - [ ] Test installing and using Podman inside the QEMU VM
  - [ ] Test cloning a QEMU VM
  - [ ] Create a script to measure
    - [ ] QEMU VM startup time
    - [x] Disk space used by a QEMU VM
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

Aug 29 18:38:30 t14s incusd[164118]: time="2026-08-29T18:38:30+02:00" level=error msg="Unable to parse system idmap" err="No map found for user"
Aug 29 18:38:30 t14s incusd[164118]: time="2026-08-29T18:38:30+02:00" level=warning msg="AppArmor support has been disabled because of lack of kernel support"
Aug 29 18:38:30 t14s incusd[164118]: time="2026-08-29T18:38:30+02:00" level=warning msg=" - AppArmor support has been disabled, Disabled because of lack of kernel support"
Aug 29 18:38:30 t14s qemu-system-x86_64[164192]: *HARK*  log.c:  92: core_log_lib_info: src version: 2.1.0
Aug 29 18:38:30 t14s qemu-system-x86_64[164192]: *HARK*  log.c:  94: core_log_lib_info: compiled with support for shutdown state
Aug 29 18:38:30 t14s qemu-system-x86_64[164192]: *HARK*  log.c:  97: core_log_lib_info: compiled with libndctl 63+
Aug 29 18:38:30 t14s qemu-system-x86_64[164196]: *HARK*  log.c:  92: core_log_lib_info: src version: 2.1.0
Aug 29 18:38:30 t14s qemu-system-x86_64[164196]: *HARK*  log.c:  94: core_log_lib_info: compiled with support for shutdown state
Aug 29 18:38:30 t14s qemu-system-x86_64[164196]: *HARK*  log.c:  97: core_log_lib_info: compiled with libndctl 63+
Aug 29 18:38:31 t14s systemd[1]: Started incus.service - Incus - Daemon.
```

Here's how I initialized Incus:

```sh
$ incus admin init
Would you like to use clustering? (yes/no) [default=no]: no
Would you like to configure a new storage pool? (yes/no) [default=yes]: yes
Name of the new storage pool [default=default]:
Name of the storage backend to use (btrfs, dir, lvm) [default=btrfs]: btrfs
Would you like to create a new btrfs subvolume under /var/lib/incus? (yes/no) [default=yes]: yes
Would you like to create a new local network bridge? (yes/no) [default=yes]: yes
What name to give the new bridge? [default=incusbr0]:
Which IPv4 address to use? (CIDR subnet notation, "auto" or "none") [default=auto]:
Which IPv6 address to use? (CIDR subnet notation, "auto" or "none") [default=auto]:
Would you like to make the server available over the network? (yes/no) [default=no]: yes
Addresses to associate (excluding ports) [default=all]:
Port to bind to [default=8443]:
Would you like cached expired images to be updated automatically? (yes/no) [default=yes]:
Would you like to see the preseed YAML file? (yes/no) [default=no]: yes
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
|           ALIAS            | FINGERPRINT | PUBLIC |           DESCRIPTION            | ARCHITECTURE |      TYPE       |   SIZE    |    PUBLICATION DATE   |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44 (3 de plus)       | 17d2b7249a1f | yes    | Fedora 44 amd64 (20260828_20:33) | x86_64       | VIRTUAL-MACHINE | 754.63MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44 (3 de plus)       | 794d87e8de86 | yes    | Fedora 44 amd64 (20260828_20:33) | x86_64       | CONTAINER       | 110.29MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/arm64 (1 de plus) | 3f1e393b552e | yes    | Fedora 44 arm64 (20260828_20:33) | aarch64      | VIRTUAL-MACHINE | 710.69MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/arm64 (1 de plus) | 29608e45e688 | yes    | Fedora 44 arm64 (20260828_20:33) | aarch64      | CONTAINER       | 104.12MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud (1 de plus) | 517e69071f1c | yes    | Fedora 44 amd64 (20260828_20:33) | x86_64       | CONTAINER       | 130.86MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud (1 de plus) | 195178d3444e | yes    | Fedora 44 amd64 (20260828_20:33) | x86_64       | VIRTUAL-MACHINE | 790.05MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud/arm64       | c12e54f7cf75 | yes    | Fedora 44 arm64 (20260828_20:33) | aarch64      | VIRTUAL-MACHINE | 745.96MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud/arm64       | ddec5bf0fb94 | yes    | Fedora 44 arm64 (20260828_20:33) | aarch64      | CONTAINER       | 123.79MiB | 2026/08/28 02:00 CEST |
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
Name: test1
Description:
State: RUNNING
Type: container
Architecture: x86_64
PID: 191282
Created: 2026/08/29 19:13 CEST
Last Used: 2026/08/29 19:13 CEST
Started: 2026/08/29 19:13 CEST

Resources:
  Processes: 16
  CPU usage:
    CPU used (in seconds): 1
  Memory usage:
    Memory (current): 87.99MiB
  Network usage:
    eth0:
      Type: broadcast
      State: UP
      Host interface: vethf0f4a29f
      MAC address: 10:66:6a:30:15:16
      MTU: 1500
      Bytes received: 13.80kB
      Bytes sent: 2.67kB
      Packets received: 36
      Packets sent: 27
      IP addresses:
        inet:  10.95.83.57/24 (global)
        inet6: fd42:15b1:7fa2:bcd0:1266:6aff:fe30:1516/64 (global)
        inet6: fe80::1266:6aff:fe30:1516/64 (link)
    lo:
      Type: loopback
      State: UP
      MTU: 65536
      Bytes received: 0B
      Bytes sent: 0B
      Packets received: 0
      Packets sent: 0
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
+-------+---------+------+------+-----------+-----------+
| NAME  |  STATE  | IPv4 | IPv6 |   TYPE    | SNAPSHOTS |
+-------+---------+------+------+-----------+-----------+
| test1 | STOPPED |      |      | CONTAINER | 0         |
+-------+---------+------+------+-----------+-----------+
```

I'll delete the container:

```sh
$ incus delete test1
$ incus list
+-----+------+------+------+------+-----------+
| NAME | STATE | IPv4 | IPv6 | TYPE | SNAPSHOTS |
+-----+------+------+------+------+-----------+
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
+-----+------+------+------+------+-----------+
| NAME | STATE | IPv4 | IPv6 | TYPE | SNAPSHOTS |
+-----+------+------+------+------+-----------+
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

## Testing incus-apply

Using [incus-apply](https://github.com/abiosoft/incus-apply), to launch instances from a declarative file.

> [!note]
>
> In this POC, I use my fork of *incus-apply* ([here](https://github.com/stephane-klein/incus-apply)), which includes this pull request: [`dev: resolve relative disk device sources`](https://github.com/abiosoft/incus-apply/pull/67)

I install *incus-apply* with [Mise](https://mise.jdx.dev/):

```ssh
$ mise install
$ incus-apply --version
incus-apply version v0.1.2-sklein-draft
git commit: 57ebccd3254818874456bdad107f7ae0ad4ee5f3
build date: 2026-08-29T20:29:19Z
```

Here is the content of a file describing the configuration of a container and a QEMU VM I want to create with *incus-apply*:

```sh
$ cat test3.incus.yaml
kind: instance
name: test3-lxc
image: images:fedora/44
profiles:
  - default
devices:
  volume1:
    type: disk
    source: ./volumes/volume1
    path: /mnt/volume1
---
kind: instance
name: test3-vm
image: images:fedora/44
vm: true
profiles:
  - default
devices:
  volume1:
    type: disk
    source: ./volumes/volume1
    path: /mnt/volume1
```

```sh
$ incus-apply test3.incus.yaml -y

Found 2 resources in 1 file.

The following actions would be performed:

  create (2):
    + instance/test3-lxc
      └─ launch
    + instance/test3-vm
      └─ launch

Summary: 2 to create.
+ instance/test3-lxc created
  └─ started
+ instance/test3-vm created
  └─ started

Summary: 2 created.

$ incus list
+-----------+---------+---------------------+------------------------------------------------+-----------------+-----------+
|    NAME   |  STATE  |        IPv4         |                      IPv6                      |      TYPE       | SNAPSHOTS |
+-----------+---------+---------------------+------------------------------------------------+-----------------+-----------+
| test3-lxc | RUNNING | 10.95.83.109 (eth0) | fd42:15b1:7fa2:bcd0:1266:6aff:fe26:967 (eth0)  | CONTAINER       | 0         |
+-----------+---------+---------------------+------------------------------------------------+-----------------+-----------+
| test3-vm  | RUNNING |                     | fd42:15b1:7fa2:bcd0:1266:6aff:febb:5e5a (eth0) | VIRTUAL-MACHINE | 0         |
+-----------+---------+---------------------+------------------------------------------------+-----------------+-----------+
```

Let me verify the mount points are accessible:

```sh
$ incus exec test3-lxc -- ls /mnt/volume1/
foobar.txt

$ incus exec test3-vm -- ls /mnt/volume1/
foobar.txt
```

*incus-apply* can also delete instances:

```sh
$ incus-apply -d test3.incus.yaml

Found 2 resources in 1 file.

The following actions would be performed:

  delete (2):
    - instance/test3-lxc
    - instance/test3-vm

Summary: 2 to delete.

Proceed to delete these resources? [y/N]: y

- instance/test3-lxc deleted
- instance/test3-vm deleted

Summary: 2 deleted, 0 skipped, 0 errors.
```

## Disk space used

```sh
$ incus list
+-----------+---------+-----------------------+--------------------------------------------------+-----------------+-----------+
|    NAME   |  STATE  |         IPv4          |                       IPv6                       |      TYPE       | SNAPSHOTS |
+-----------+---------+-----------------------+--------------------------------------------------+-----------------+-----------+
| test3-lxc | RUNNING | 10.95.83.109 (eth0)   | fd42:15b1:7fa2:bcd0:1266:6aff:fe26:967 (eth0)    | CONTAINER       | 0         |
+-----------+---------+-----------------------+--------------------------------------------------+-----------------+-----------+
| test3-vm  | RUNNING | 10.95.83.145 (enp5s0) | fd42:15b1:7fa2:bcd0:1266:6aff:febb:5e5a (enp5s0) | VIRTUAL-MACHINE | 0         |
+-----------+---------+-----------------------+--------------------------------------------------+-----------------+-----------+

$ mise run incus-btrfs-usage
[incus-btrfs-usage] $ sudo bash scripts/incus-btrfs-usage.sh
INSTANCE                     TYPE                         EXCLUSIVE       SHARED
--------                     ----                         ---------       ------
test3-lxc                    CONTAINER (LXC)             108.91MiB      501.94MiB
test3-vm                     VIRTUAL-MACHINE (QEMU)      644.38MiB        1.18GiB

Overall usage of pool 'default':
       Total   Exclusive  Set shared  Filename
     4.29GiB   753.91MiB     1.66GiB  /var/lib/incus/storage-pools/default
```
