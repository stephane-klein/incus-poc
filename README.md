# Incus POC

I created this POC to test, learn how to use, and evaluate [Incus](https://github.com/lxc/incus/).

The driving motivation behind this POC is a likely future refactoring of [sklein-devbox](https://github.com/stephane-klein/sklein-devbox) to Incus.

## Roadmap

- [ ] Tests to run on Incus in LXC mode
  - [ ] Launch a basic Fedora
  - [ ] Create a custom Fedora image
    - [ ] Test pushing and pulling this image
  - [ ] Test that mounting a host directory into the LXC container works
  - [ ] Test installing and using Podman inside the LXC container
  - [ ] Test SSH access to the LXC container
  - [ ] Test cloning an LXC container
  - [ ] Test starting and stopping an LXC container
  - [ ] Create a script to measure
    - [ ] LXC container startup time
    - [ ] Disk space used by an LXC container
    - [ ] RAM usage of an LXC container
- [ ] Tests to run on Incus in QEMU mode
  - [ ] Launch a basic Fedora
  - [ ] Create a custom Fedora image
    - [ ] Test pushing and pulling this image
  - [ ] Test that mounting a host directory into the QEMU VM works
  - [ ] Test installing and using Podman inside the QEMU VM
  - [ ] Test SSH access to the QEMU VM
  - [ ] Test cloning a QEMU VM
  - [ ] Test starting and stopping a QEMU VM
  - [ ] Create a script to measure
    - [ ] QEMU VM startup time
    - [ ] Disk space used by a QEMU VM
    - [ ] RAM usage of a QEMU VM
- [ ] Test [IncusOS](https://linuxcontainers.org/incus-os/introduction/) by installing it on my [Tuxedo Infinity Flexible 14 Gen 1](https://notes.sklein.xyz/Tuxedo%20Infinity%20Flexible%2014%20Gen%201/) laptop, which I currently don't use and which could serve as a development server until RAM prices drop

## AI-Assisted Development

This project was developed using:

- [OpenCode](https://opencode.ai) CLI — coding assistant workflow (not vibe coding)
- Models: DeepSeek V4 Flash
