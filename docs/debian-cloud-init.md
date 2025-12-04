# Debian cloud-init for general VMs (Paper, GUI, tools)

Use this for Debian guests (e.g., Paper 1.8.8, GUI boxes, tooling). It sets up a user with SSH key, installs basics and Java 8, and leaves hooks for GUI or server roles.

## cloud-init.yml
```yaml
#cloud-config
hostname: debian-guest-1
users:
  - name: engineer
    ssh-authorized-keys:
      - ssh-ed25519 AAAA...yourkey...
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

package_update: true
package_upgrade: false
packages:
  - curl
  - ca-certificates
  - unzip
  - htop
  - openjdk-8-jre-headless   # for Paper 1.8.8
  - screen
  - net-tools

runcmd:
  - systemctl enable --now ssh
  # Optional: add your Paper server jar setup here (download paper-1.8.8, create service).
  # Optional: for GUI/noVNC, install xfce4 and tightvncserver or your preferred stack.
```

## Host-side build and launch (libvirt)
```bash
cloud-localds debian-seed.iso cloud-init.yml
virt-install \
  --name debian-guest-1 \
  --memory 4096 --vcpus 4 \
  --disk path=/var/lib/libvirt/images/debian-guest-1.qcow2,size=40 \
  --cdrom /var/lib/libvirt/images/debian-12.7.0-amd64-netinst.iso \
  --cloud-init debian-seed.iso \
  --network network=br0-net \
  --os-variant detect=on
```

- Swap `--network network=br0-net` with `--network network=default` for NAT.
- Replace `AAAA...yourkey...` with your SSH public key.
- Add GUI packages if needed: `xfce4`, `xfce4-goodies`, `xrdp`/`tightvncserver`, `novnc` depending on your stack.
