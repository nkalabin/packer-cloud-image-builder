# packer-cloud-image-builder

Templates and scaffolding to build cloud images (Ubuntu and more) with HashiCorp Packer. The project is a “constructor”: take the working base, plug in your cloud-init/scripts, adjust the builder settings for your target platform (QEMU/Libvirt/OpenStack, etc.), and get reproducible images.

## Status
This repository is evolving. Features, examples, and layout may change over time. Expect breaking changes until a stable baseline is declared.

## Why
Custom images are often needed across different cloud platforms (e.g., OpenStack). This repo provides working examples, structure, and practices so you can start quickly and adapt to your needs.

## Features
- The list below reflects the current state and may change as the project grows.
- **Ready-to-use Ubuntu 24.04 example** in `Ubuntu-Example`
- **cloud-init** (`http/user-data`, `http/meta-data`) for initial configuration
- **Post-provision scripts** (`scripts/cleanup.sh`) for final image cleanup
- Reproducible builds via Packer (`*.pkr.hcl`)

## Repository structure
The structure shown is illustrative and can evolve. Check the repository for the latest layout.

```
Ubuntu-Example/
  http/
    meta-data
    user-data
  scripts/
    cleanup.sh
  ubuntu-24.03-generic-image.pkr.hcl
README.md
```

## Requirements

- Packer: see `https://developer.hashicorp.com/packer/install`
- QEMU (local builds via the qemu builder): `https://www.qemu.org/download/#macos`

macOS/Apple Silicon notes:
- The author builds x86_64 images on Apple Silicon. You may need extra settings in `*.pkr.hcl` (QEMU emulation, acceleration flags, etc.). Adjust the builder settings to match your host architecture.

## Quick start

Below is an example of building an Ubuntu image from `Ubuntu-Example`.

1) Initialize Packer dependencies

```bash
cd Ubuntu-Example
packer init .
```

2) Validate templates

```bash
packer validate ubuntu-24.03-generic-image.pkr.hcl
```

3) Build the image

```bash
packer build ubuntu-24.03-generic-image.pkr.hcl
```

After a successful build, the artifact (qcow2/raw/etc.) will be created according to the builder settings in the HCL.

## Customization

- **cloud-init**:
  - Edit `Ubuntu-Example/http/user-data` and `Ubuntu-Example/http/meta-data` for your environment (users, ssh, packages, etc.).

- **Post-provision scripts**:
  - Add/adjust scripts in `Ubuntu-Example/scripts/` and wire them in via HCL provisioners. For example, `cleanup.sh` can clear caches, logs, and shell histories prior to finalizing the image.

- **Builder settings**:
  - Open `Ubuntu-Example/ubuntu-24.03-generic-image.pkr.hcl` and configure the builder (QEMU/Libvirt/OpenStack) for your platform: architecture, disk/format, size, kernel/init options, acceleration flags on macOS, etc.

## Supported platforms

These templates are meant to be adapted to different platforms. The current example demonstrates the QEMU builder. For OpenStack/other providers, check the corresponding Packer builders and port the logic into your own `*.pkr.hcl`.

## Roadmap (high-level)
- Add more distros and versions
- Introduce variables and `-var-file` presets

## Contributing
Contributions are welcome. If you plan significant changes to the layout or features, please open an issue first to discuss the approach. When adding new examples, keep a similar structure to `Ubuntu-Example` for consistency.

## Debugging and tips

- Run `packer validate` before builds — it catches most configuration issues early.
- Enable verbose logging when needed:

```bash
PACKER_LOG=1 packer build ubuntu-24.03-generic-image.pkr.hcl
```

- When building x86_64 on Apple Silicon, carefully tune QEMU parameters (acceleration/emulation). In `*.pkr.hcl`, you can set machine type, accel, and related options.
- Inspect cloud-init logs inside the built VM if initialization didn’t go as expected (`/var/log/cloud-init.log`, `/var/log/cloud-init-output.log`).

## Useful links

- Packer Docs: `https://developer.hashicorp.com/packer/docs`
- QEMU: `https://www.qemu.org/`
- cloud-init: `https://cloud-init.io/`

---

To add a new example (different distro/provider), copy `Ubuntu-Example`, rename it, and adapt the HCL/scripts/cloud-init to your requirements.
