# Incus POC

I created this POC to test, learn how to use, and evaluate [Incus](https://github.com/lxc/incus/).

The driving motivation behind this POC is a likely future refactoring of [sklein-devbox](https://github.com/stephane-klein/sklein-devbox) to Incus.

## Roadmap

- [ ] Tests to run on Incus in LXC mode
  - [x] Launch a basic Fedora
  - [x] Test starting and stopping an LXC container
  - [x] Launch an LXC container with [incus-apply](https://incus-apply.abiosoft.com/)
  - [x] Test that mounting a host directory into the LXC container works
  - [x] Test SSH access to the LXC container
  - [x] Create a custom Fedora image with [distrobuilder](https://github.com/lxc/distrobuilder)
    - [x] Test pushing and pulling this image (see in [`./build-images/`](./build-images/))
  - [x] Test installing and using Podman inside the LXC container
  - [ ] Test cloning an LXC container
  - [x] Test setup Netbird installation and configuration
  - [ ] Create a script to measure
    - [ ] LXC container startup time
    - [x] Disk space used by an LXC container
    - [ ] RAM usage of an LXC container
- [ ] Tests to run on Incus in QEMU mode
  - [x] Launch a basic Fedora
  - [x] Test starting and stopping a QEMU VM
  - [x] Launch a QEMU VM with [incus-apply](https://incus-apply.abiosoft.com/)
  - [x] Test that mounting a host directory into the QEMU VM works
  - [x] Test SSH access to the QEMU VM
  - [x] Create a custom Fedora image with [distrobuilder](https://github.com/lxc/distrobuilder)
    - [x] Test pushing and pulling this image (see in [`./build-images/`](./build-images/))
  - [x] Test installing and using Podman inside the QEMU VM
  - [ ] Test cloning a QEMU VM
  - [x] Test setup Netbird installation and configuration
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

Browse the official Incus images online: <https://images.linuxcontainers.org>.

```sh
$ incus image list images:fedora/44
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
|           ALIAS            | FINGERPRINT | PUBLIC |           DESCRIPTION            | ARCHITECTURE |      TYPE       |   SIZE    |    PUBLICATION DATE   |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44 (3 more)       | 17d2b7249a1f | yes    | Fedora 44 amd64 (20260828_20:33) | x86_64       | VIRTUAL-MACHINE | 754.63MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44 (3 more)       | 794d87e8de86 | yes    | Fedora 44 amd64 (20260828_20:33) | x86_64       | CONTAINER       | 110.29MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/arm64 (1 more) | 3f1e393b552e | yes    | Fedora 44 arm64 (20260828_20:33) | aarch64      | VIRTUAL-MACHINE | 710.69MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/arm64 (1 more) | 29608e45e688 | yes    | Fedora 44 arm64 (20260828_20:33) | aarch64      | CONTAINER       | 104.12MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud (1 more) | 517e69071f1c | yes    | Fedora 44 amd64 (20260828_20:33) | x86_64       | CONTAINER       | 130.86MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud (1 more) | 195178d3444e | yes    | Fedora 44 amd64 (20260828_20:33) | x86_64       | VIRTUAL-MACHINE | 790.05MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud/arm64       | c12e54f7cf75 | yes    | Fedora 44 arm64 (20260828_20:33) | aarch64      | VIRTUAL-MACHINE | 745.96MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
| fedora/44/cloud/arm64       | ddec5bf0fb94 | yes    | Fedora 44 arm64 (20260828_20:33) | aarch64      | CONTAINER       | 123.79MiB | 2026/08/28 02:00 CEST |
+-----------------------------+--------------+--------+----------------------------------+--------------+-----------------+-----------+-----------------------+
```

Here are the details of an image:

```sh
$ incus image show images:fedora/44/cloud
auto_update: false
properties:
  architecture: amd64
  description: Fedora 44 amd64 (20260829_20:33)
  os: Fedora
  release: "44"
  serial: "20260829_20:33"
  type: squashfs
  variant: cloud
public: true
expires_at: 1970-01-01T00:00:00Z
profiles: []
```

I notice the images are very up to date. Incus uses a publicly accessible Jenkins instance to build its images; here is the Fedora image job: <https://jenkins.linuxcontainers.org/job/image-fedora/>.

## Launching my first LXC Fedora container

```sh
$ incus launch images:fedora/44/cloud test1
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
      IP addresses:
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

## Launching my first QEMU Fedora VM

```sh
$ incus launch images:fedora/44/cloud test2 --vm
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

## Launching an instance with cloud-init configured SSH access

Here is a config file containing a [cloud-init](https://cloud-init.io/) configuration that installs and configures an SSH server and installs my public SSH key on the server:

```sh
$ cat test3-lxc.yaml
config:
  cloud-init.user-data: |
    #cloud-config
    packages:
      - openssh-server
    runcmd:
      - systemctl enable --now sshd
    users:
      - name: fedora
        ssh_authorized_keys:
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEzyNFlEuHIlewK0B8B0uAc9Q3JKjzi7myUMhvtB3JmA2BqHfVHyGimuAajSkaemjvIlWZ3IFddf0UibjOfmQH57/faxcNEino+6uPRjs0pFH8sNKWAaPX1qYqOFhB3m+om0hZDeQCyZ1x1R6m+B0VJHWQ3pxFaxQvL/K+454AmIWB0b87MMHHX0UzUja5D6sHYscHo57rzJI1fc66+AFz4fcRd/z+sUsDlLSIOWfVNuzXuGpKYuG+VW9moiMTUo8gTE9Nam6V2uFwv2w3NaOs/2KL+PpbY662v+iIB2Yyl4EP1JgczShOoZkLatnw823nD1muC8tYODxVq7Xf7pM/NSCf3GPCXtxoOEqxprLapIet0uBSB4oNZhC9h7K/1MEaBGbU+E2J5/5hURYDmYXy6KZWqrK/OEf4raGqx1bsaWcONOfIVXbj3zXTUobsqSkyCkkR3hJbf39JZ8/6ONAJS/3O+wFZknFJYmaRPuaWiLZxRj5/gw01vkNVMrogOIkQtzNDB6fh2q27ghSRkAkM8EVqkW21WkpB7y16Vzva4KSZgQcFcyxUTqG414fP+/V38aCopGpqB6XjnvyRorPHXjm2ViVWbjxmBSQ9aK0+2MeKA9WmHN0QoBMVRPrN6NBa3z20z1kMQ/qlRXiDFOEkuW4C1n2KTVNd6IOGE8AufQ== contact@stephane-klein.info
```

Launching a "cloud" type LXC instance:

```sh
$ incus launch images:fedora/44/cloud test3-lxc < test3-lxc.yaml
$ incus list
+-----------+---------+---------------------+------------------------------------------------+-----------+-------------+
|    NAME   |  STATE  |        IPv4         |                      IPv6                      |   TYPE    | SNAPSHOTS  |
+-----------+---------+---------------------+------------------------------------------------+-----------+-------------+
| test3-lxc | RUNNING | 10.95.83.192 (eth0) | fd42:15b1:7fa2:bcd0:1266:6aff:fe54:8ca1 (eth0) | CONTAINER | 0           |
+-----------+---------+---------------------+------------------------------------------------+-----------+-------------+

$ ssh fedora@10.95.83.192
[fedora@test3-lxc ~]$ exit
```

I'll delete the container:

```sh
$ incus delete test3-lxc
```

## Testing incus-apply

Using [incus-apply](https://github.com/abiosoft/incus-apply), to launch instances from a declarative file.

> [!note]
>
> In this POC, I use my fork of *incus-apply* ([here](https://github.com/stephane-klein/incus-apply)), which includes this pull request: [`dev: resolve relative disk device sources`](https://github.com/abiosoft/incus-apply/pull/67)

I install *incus-apply* with [Mise](https://mise.jdx.dev/):

```sh
$ mise install
$ incus-apply --version
incus-apply version v0.1.2-sklein-draft
git commit: 57ebccd3254818874456bdad107f7ae0ad4ee5f3
build date: 2026-08-29T20:29:19Z
```

Here is the content of a file describing the configuration of a container and a QEMU VM I want to create with *incus-apply*:

```sh
$ cat test4.incus.yaml
kind: instance
name: test4-lxc
image: images:fedora/44/cloud
profiles:
  - default
devices:
  volume1:
    type: disk
    source: ./volumes/volume1
    path: /mnt/volume1
config:
  cloud-init.user-data: |
    #cloud-config
    packages:
      - openssh-server
    runcmd:
      - systemctl enable --now sshd
    users:
      - name: fedora
        ssh_authorized_keys:
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEzyNFlEuHIlewK0B8B0uAc9Q3JKjzi7myUMhvtB3JmA2BqHfVHyGimuAajSkaemjvIlWZ3IFddf0UibjOfmQH57/faxcNEino+6uPRjs0pFH8sNKWAaPX1qYqOFhB3m+om0hZDeQCyZ1x1R6m+B0VJHWQ3pxFaxQvL/K+454AmIWB0b87MMHHX0UzUja5D6sHYscHo57rzJI1fc66+AFz4fcRd/z+sUsDlLSIOWfVNuzXuGpKYuG+VW9moiMTUo8gTE9Nam6V2uFwv2w3NaOs/2KL+PpbY662v+iIB2Yyl4EP1JgczShOoZkLatnw823nD1muC8tYODxVq7Xf7pM/NSCf3GPCXtxoOEqxprLapIet0uBSB4oNZhC9h7K/1MEaBGbU+E2J5/5hURYDmYXy6KZWqrK/OEf4raGqx1bsaWcONOfIVXbj3zXTUobsqSkyCkkR3hJbf39JZ8/6ONAJS/3O+wFZknFJYmaRPuaWiLZxRj5/gw01vkNVMrogOIkQtzNDB6fh2q27ghSRkAkM8EVqkW21WkpB7y16Vzva4KSZgQcFcyxUTqG414fP+/V38aCopGpqB6XjnvyRorPHXjm2ViVWbjxmBSQ9aK0+2MeKA9WmHN0QoBMVRPrN6NBa3z20z1kMQ/qlRXiDFOEkuW4C1n2KTVNd6IOGE8AufQ== contact@stephane-klein.info
---
kind: instance
name: test4-vm
image: images:fedora/44/cloud
vm: true
profiles:
  - default
devices:
  volume1:
    type: disk
    source: ./volumes/volume1
    path: /mnt/volume1
config:
  cloud-init.user-data: |
    #cloud-config
    packages:
      - openssh-server
    runcmd:
      - systemctl enable --now sshd
    users:
      - name: fedora
        ssh_authorized_keys:
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEzyNFlEuHIlewK0B8B0uAc9Q3JKjzi7myUMhvtB3JmA2BqHfVHyGimuAajSkaemjvIlWZ3IFddf0UibjOfmQH57/faxcNEino+6uPRjs0pFH8sNKWAaPX1qYqOFhB3m+om0hZDeQCyZ1x1R6m+B0VJHWQ3pxFaxQvL/K+454AmIWB0b87MMHHX0UzUja5D6sHYscHo57rzJI1fc66+AFz4fcRd/z+sUsDlLSIOWfVNuzXuGpKYuG+VW9moiMTUo8gTE9Nam6V2uFwv2w3NaOs/2KL+PpbY662v+iIB2Yyl4EP1JgczShOoZkLatnw823nD1muC8tYODxVq7Xf7pM/NSCf3GPCXtxoOEqxprLapIet0uBSB4oNZhC9h7K/1MEaBGbU+E2J5/5hURYDmYXy6KZWqrK/OEf4raGqx1bsaWcONOfIVXbj3zXTUobsqSkyCkkR3hJbf39JZ8/6ONAJS/3O+wFZknFJYmaRPuaWiLZxRj5/gw01vkNVMrogOIkQtzNDB6fh2q27ghSRkAkM8EVqkW21WkpB7y16Vzva4KSZgQcFcyxUTqG414fP+/V38aCopGpqB6XjnvyRorPHXjm2ViVWbjxmBSQ9aK0+2MeKA9WmHN0QoBMVRPrN6NBa3z20z1kMQ/qlRXiDFOEkuW4C1n2KTVNd6IOGE8AufQ== contact@stephane-klein.info
```

```sh
$ incus-apply -y test4.incus.yaml

Found 2 resources in 1 file.

The following actions would be performed:

  create (2):
    + instance/test4-lxc
      └─ launch, cloud-init
    + instance/test4-vm
      └─ launch, cloud-init

Summary: 2 to create.
+ instance/test4-lxc created
  └─ started
+ instance/test4-vm created
  └─ started

Summary: 2 created.

$ incus list
+-----------+---------+-----------------------+--------------------------------------------------+-----------------+-------------+
|    NAME   |  STATE  |         IPv4          |                       IPv6                       |      TYPE       | SNAPSHOTS  |
+-----------+---------+-----------------------+--------------------------------------------------+-----------------+-------------+
| test4-lxc | RUNNING | 10.95.83.200 (eth0)   | fd42:15b1:7fa2:bcd0:1266:6aff:fe2e:5cc7 (eth0)   | CONTAINER       | 0           |
+-----------+---------+-----------------------+--------------------------------------------------+-----------------+-------------+
| test4-vm  | RUNNING | 10.95.83.107 (enp5s0) | fd42:15b1:7fa2:bcd0:1266:6aff:fe70:dcc4 (enp5s0) | VIRTUAL-MACHINE | 0           |
+-----------+---------+-----------------------+--------------------------------------------------+-----------------+-------------+
```

Let me verify the mount points are accessible:

```sh
$ incus exec test4-lxc -- ls /mnt/volume1/
foobar.txt

$ incus exec test4-vm -- ls /mnt/volume1/
foobar.txt
```

I test SSH access:

```
$ ssh fedora@10.95.83.200
[fedora@test4-lxc ~]$ exit
logout
Connection to 10.95.83.200 closed.

$ ssh fedora@10.95.83.107
[fedora@test4-vm ~]$
logout
```

*incus-apply* can also delete instances:

```sh
$ incus-apply -d test4.incus.yaml

Found 2 resources in 1 file.

The following actions would be performed:

  delete (2):
    - instance/test4-lxc
    - instance/test4-vm

Summary: 2 to delete.

Proceed to delete these resources? [y/N]: y

- instance/test4-lxc deleted
- instance/test4-vm deleted

Summary: 2 deleted, 0 skipped, 0 errors.
```

## Disk space used

```sh
$ incus list
+-----------+---------+-----------------------+--------------------------------------------------+-----------------+-----------+
|    NAME   |  STATE  |         IPv4          |                       IPv6                       |      TYPE       | SNAPSHOTS |
+-----------+---------+-----------------------+--------------------------------------------------+-----------------+-----------+
| test4-lxc | RUNNING | 10.95.83.109 (eth0)   | fd42:15b1:7fa2:bcd0:1266:6aff:fe26:967 (eth0)    | CONTAINER       | 0         |
+-----------+---------+-----------------------+--------------------------------------------------+-----------------+-----------+
| test4-vm  | RUNNING | 10.95.83.145 (enp5s0) | fd42:15b1:7fa2:bcd0:1266:6aff:febb:5e5a (enp5s0) | VIRTUAL-MACHINE | 0         |
+-----------+---------+-----------------------+--------------------------------------------------+-----------------+-----------+

$ mise run incus-btrfs-usage
[incus-btrfs-usage] $ sudo bash scripts/incus-btrfs-usage.sh
INSTANCE                     TYPE                         EXCLUSIVE       SHARED
--------                     ----                         ---------       ------
test4-lxc                    CONTAINER (LXC)             108.91MiB      501.94MiB
test4-vm                     VIRTUAL-MACHINE (QEMU)      644.38MiB        1.18GiB

Overall usage of pool 'default':
       Total   Exclusive  Set shared  Filename
     4.29GiB   753.91MiB     1.66GiB  /var/lib/incus/storage-pools/default
```

## Using Distrobuilder to create custom images

### Installation

I couldn't find a [distrobuilder](https://github.com/lxc/distrobuilder) package for Fedora: https://packages.fedoraproject.org/search?query=distrobuilder

Here are the packages to install on Fedora:

```sh
$ sudo dnf install golang gcc debootstrap rsync gnupg2 squashfs-tools git make hivex genisoimage gpgme-devel btrfs-progs-devel umoci
...
```

Then, I install *distrobuilder* with Mise:

```sh
$ mise install
...
$ distrobuilder --version
3.3.1
```

### Creating a Fedora cloud image

Description of the Fedora images to create: [`build-images/fedora.yaml`](build-images/fedora.yaml).  
These images integrate `openssh-server` directly and start it.

Build an image for LXC container:

```sh
$ mise run //build-images:build-lxc

[...snip...]

INFO   [2026-09-01T11:03:44+02:00] Removing cache directory
total 132M
drwxr-xr-x 1 stephane stephane   54  Sep  1 11:03 .
drwxr-xr-x 1 stephane stephane  182  Sep  1 11:02 ..
-rw-r--r-- 1 stephane stephane 1.4K  Sep  1 11:03 incus.tar.xz
-rw-r--r-- 1 stephane stephane 132M  Sep  1 11:03 rootfs.squashfs
```

Build an image for QEMU VM:

```sh
$ mise run //build-images:build-vm

[...snip...]

INFO   [2026-09-01T11:40:04+02:00] Creating Incus image                          compression=xz type=split vm=true
INFO   [2026-09-01T11:40:39+02:00] Removing cache directory
total 808M
drwxr-xr-x 1 stephane stephane   44  Sep  1 11:40 .
drwxr-xr-x 1 stephane stephane  182  Sep  1 11:02 ..
-rw-r--r-- 1 stephane stephane 810M  Sep  1 11:40 disk.qcow2
-rw-r--r-- 1 stephane stephane 1.4K  Sep  1 11:40 incus.tar.xz
```

## Create instance with Netbird enrolement


I use a Mise task to prepare the `test5-custom-fedora-image.yaml` file from the template [`./test5-custom-fedora-image.yaml.j2`](./test5-custom-fedora-image.yaml.j2).  
I use a template because the file embeds my Netbird key — a secret that lets newly created instances automatically enroll in the `incus` NetBird group I created [here](https://github.com/stephane-klein/homelab.sklein.xyz/blob/bb6bfa27aa523d7818f32640d5a235b43c3810a3/README.md?plain=1#L163).

```sh
$ mise run //:render-test5-custom-fedora-image-yaml
```

```sh
$ incus-apply test5-custom-fedora-image.yaml

Found 2 resources in 1 file.

The following actions would be performed:

  create (2):
    + instance/test5-lxc
      └─ launch, cloud-init
    + instance/test5-vm
      └─ launch, cloud-init

Summary: 2 to create.

Proceed to apply these changes? [y/N]: y

+ instance/test5-lxc created
  └─ started
+ instance/test5-vm created
  └─ started
  └─ waiting for incus agent  ⠴
```

```sh
$ incus list
+-----------+---------+----------------------+--------------------------------------------------+-----------------+-------------+
|    NAME   |  STATE  |         IPv4         |                       IPv6                       |      TYPE       | SNAPSHOTS  |
+-----------+---------+----------------------+--------------------------------------------------+-----------------+-------------+
| test5-lxc | RUNNING | 10.95.83.19 (eth0)   | fd42:15b1:7fa2:bcd0:1266:6aff:fe8f:db70 (eth0)   | CONTAINER       | 0           |
+-----------+---------+----------------------+--------------------------------------------------+-----------------+-------------+
| test5-vm  | RUNNING | 10.95.83.87 (enp5s0) | fd42:15b1:7fa2:bcd0:1266:6aff:fe51:952b (enp5s0) | VIRTUAL-MACHINE | 0           |
+-----------+---------+----------------------+--------------------------------------------------+-----------------+-------------+
```

I connect to these instances via SSH:

```sh
$ ssh fedora@10.95.83.19
[fedora@test5-lxc ~]$ uname --all
Linux test5-lxc 7.1.10-100.fc43.x86_64 #1 SMP PREEMPT_DYNAMIC Sun Aug 23 16:26:01 UTC 2026 x86_64 GNU/Linux
[fedora@test5-lxc ~]$ exit
logout

$ ssh fedora@10.95.83.87
[fedora@test5-vm ~]$ uname --all
Linux test5-vm 7.1.12-200.fc44.x86_64 #1 SMP PREEMPT_DYNAMIC Fri Aug 28 14:00:18 UTC 2026 x86_64 GNU/Linux
[fedora@test5-vm ~]$
```

I can see cloud-init worked properly, and my SSH key is correctly installed.

### Podman is installed and ready to use

Since these cloud-init configurations enroll the instances in my Netbird network, I can also connect to them using:

```sh
$ ssh fedora@test5-lxc.homelab.stephane-klein.info # or ssh fedora@test5-lxc
[fedora@test5-lxc ~]$ podman run -d -p 8080:80 --name whoami docker.io/traefik/whoami
...
[fedora@test5-lxc ~]$ exit
$ ssh fedora@test5-vm.homelab.stephane-klein.info # or ssh fedora@test5-vm
[fedora@test5-vm ~]$ podman run -d -p 8080:80 --name whoami docker.io/traefik/whoami
...
[fedora@test5-vm ~]$ exit
```

In this example, a [`whoami`](https://hub.docker.com/r/traefik/whoami) container is started and is accessible via the VPN hostnames of the instances:

```sh
$ curl http://test5-lxc.homelab.stephane-klein.info:8080
Hostname: a6782f4fe689
IP: 127.0.0.1
IP: ::1
IP: 10.95.83.52
IP: fd42:15b1:7fa2:bcd0:1266:6aff:fe6d:d77c
IP: fe80::6ccb:57ff:fed5:f79e
RemoteAddr: [fd0e:5069:2174:137b:7db2:51cb:33f7:339]:46934
GET / HTTP/1.1
Host: test5-lxc.homelab.stephane-klein.info:8080
User-Agent: curl/8.15.0
Accept: */*
```

```sh
$ curl http://test5-vm.homelab.stephane-klein.info:8080
Hostname: 7e9845b445b8
IP: 127.0.0.1
IP: ::1
IP: 10.95.83.210
IP: fd42:15b1:7fa2:bcd0:1266:6aff:fea0:2d25
IP: fe80::1427:b8ff:fedd:d65f
RemoteAddr: [fd0e:5069:2174:137b:7db2:51cb:33f7:339]:60348
GET / HTTP/1.1
Host: test5-vm.homelab.stephane-klein.info:8080
User-Agent: curl/8.15.0
Accept: */*
```

Destroying the instances:

```sh
$ incus-apply -d test5-custom-fedora-image.yaml

Found 2 resources in 1 file.

The following actions would be performed:

  delete (2):
    - instance/test5-lxc
    - instance/test5-vm

Summary: 2 to delete.

Proceed to delete these resources? [y/N]: y

- instance/test5-lxc deleted
- instance/test5-vm deleted

Summary: 2 deleted, 0 skipped, 0 errors.
```

## Installing IncusOS

See [`./incus-os/`](./incus-os/).
