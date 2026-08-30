# build-images

Custom Fedora images for Incus (container + VM), built with
[distrobuilder](https://linuxcontainers.org/distrobuilder/docs/latest/) from
`fedora.yaml`.

Build and import them with:

```sh
$ mise run //build-images:build-lxc
$ mise run //build-images:build-vm
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
