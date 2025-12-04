# Clear Linux cloud-init for Rust Ω engine VMs

Use this on Clear Linux guests (headless) to bootstrap a Rust-ready VM. It installs base bundles, enables SSH, installs Rust via rustup, and leaves a placeholder for your Ω engine service.

## cloud-init.yml
```yaml
#cloud-config
hostname: clear-engine-1
users:
  - name: engineer
    ssh-authorized-keys:
      - ssh-ed25519 AAAA...yourkey...
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

package_update: true
package_upgrade: false
runcmd:
  - swupd bundle-add openssh-server curl network-basic storage-utils
  - systemctl enable --now sshd
  - su - engineer -c "curl https://sh.rustup.rs -sSf | sh -s -- -y --profile=minimal"
  - su - engineer -c "$HOME/.cargo/bin/rustup default stable"
  - timedatectl set-timezone UTC
  # TODO: place your omega-engine binary and systemd service here
```

## Host-side build and launch (libvirt)
```bash
cloud-localds seed.iso cloud-init.yml
virt-install \
  --name clear-engine-1 \
  --memory 4096 --vcpus 4 \
  --disk path=/var/lib/libvirt/images/clear-engine-1.qcow2,size=20 \
  --cdrom /var/lib/libvirt/images/clear-<version>-live.iso \
  --cloud-init seed.iso \
  --network network=br0-net \
  --os-variant detect=on
```

- Swap `--network network=br0-net` with `--network network=default` for NAT.
- Replace `AAAA...yourkey...` with your SSH public key.
- Add `swupd bundle-add editors dev-utils` if you want a fuller toolchain.

## Host-side one-shot script (optional)
Create `bootstrap-clear-engine.sh` on the host to spin up one VM (adapt and loop for engine1..engine7):
```bash
#!/usr/bin/env bash
set -euo pipefail

IMG_DIR=/var/lib/libvirt/images
VM_NAME=${1:-engine0}
RAM_MB=4096
VCPUS=2
NET=default         # or br0-net
SEED=seed.iso       # cloud-init seed, if you use cloud-init instead of image default user

sudo mkdir -p "$IMG_DIR"
cd "$IMG_DIR"

if [ ! -f clear-engine0.img ]; then
  sudo curl -LO https://cdn.download.clearlinux.org/releases/current/clear/clear-*-cloudguest.img.xz
  sudo unxz clear-*-cloudguest.img.xz
  sudo mv clear-*-cloudguest.img clear-engine0.img
fi

sudo virt-install \
  --name "$VM_NAME" \
  --memory "$RAM_MB" \
  --vcpus "$VCPUS" \
  --disk path="$IMG_DIR/clear-engine0.img",format=qcow2 \
  --os-variant generic \
  --import \
  --network network="$NET" \
  --noautoconsole

virsh domifaddr "$VM_NAME"
echo "VM $VM_NAME created. Use virsh console $VM_NAME or ssh clr@<ip> to enter."
```
Make it executable: `chmod +x bootstrap-clear-engine.sh`. Adjust `NET`, RAM, vCPUs, and image name as needed; wrap in a loop for multiple engines.

## Host-side multi-engine loop (engine0..engine7)
Example driver script `launch-engines.sh` to create eight Clear engines with unique disks and names:
```bash
#!/usr/bin/env bash
set -euo pipefail

IMG_DIR=/var/lib/libvirt/images
BASE_IMG=clear-engine-base.img
NET=br0-net       # default to bridge for direct LAN; switch to 'default' for NAT
RAM_MB=8192
VCPUS=4
CLOUD_INIT_SEED=/var/lib/libvirt/images/seed.iso  # optional: cloud-init seed; leave empty to skip

sudo mkdir -p "$IMG_DIR"
cd "$IMG_DIR"

# Download base image once
if [ ! -f "$BASE_IMG" ]; then
  sudo curl -LO https://cdn.download.clearlinux.org/releases/current/clear/clear-*-cloudguest.img.xz
  sudo unxz clear-*-cloudguest.img.xz
  sudo mv clear-*-cloudguest.img "$BASE_IMG"
fi

for i in $(seq 0 7); do
  NAME="engine$i"
  DISK="$IMG_DIR/${NAME}.qcow2"
  if virsh dominfo "$NAME" >/dev/null 2>&1; then
    echo "$NAME already exists, skipping"
    continue
  fi
  echo "Creating $NAME..."
  sudo qemu-img create -f qcow2 -b "$BASE_IMG" "$DISK" 20G
  CMD=(sudo virt-install
    --name "$NAME"
    --memory "$RAM_MB"
    --vcpus "$VCPUS"
    --disk path="$DISK",format=qcow2
    --os-variant generic
    --import
    --network network="$NET"
    --noautoconsole)
  if [ -n "$CLOUD_INIT_SEED" ]; then
    CMD+=(--cloud-init "$CLOUD_INIT_SEED")
  fi
  "${CMD[@]}"
done

echo "Current VMs:"
virsh list --all
```

Notes:
- Uses QCOW2 with a shared base image; delete or convert to full images if you prefer no backing files.
- Adjust RAM/vCPU per engine.
- Swap `NET` to `br0-net` for bridge.
- Add cloud-init seed or post-boot provisioning as needed.***

## One-shot host script to download, seed, and launch engines 0–7
Save as `one-shot-engines.sh` (NAT by default; set NET=br0-net for bridge):
```bash
#!/usr/bin/env bash
set -euo pipefail

IMG_DIR=/var/lib/libvirt/images
BASE_IMG="$IMG_DIR/clear-engine-base.img"
SEED="$IMG_DIR/seed.iso"      # build this once from cloud-init.yml
NET=default       # NAT; change to br0-net for bridge
RAM_MB=8192
VCPUS=8
COUNT=8

sudo mkdir -p "$IMG_DIR"
cd "$IMG_DIR"

# Require cloud-init seed upfront
if [ ! -f "$SEED" ]; then
  echo "Missing seed.iso at $SEED (build with: cloud-localds $SEED cloud-init.yml)" >&2
  exit 1
fi

# Download base image once
if [ ! -f "$BASE_IMG" ]; then
  sudo curl -LO https://cdn.download.clearlinux.org/releases/current/clear/clear-*-cloudguest.img.xz
  sudo unxz clear-*-cloudguest.img.xz
  sudo mv clear-*-cloudguest.img "$BASE_IMG"
fi

for i in $(seq 0 $((COUNT-1))); do
  NAME="engine$i"
  DISK="$IMG_DIR/${NAME}.qcow2"
  if virsh dominfo "$NAME" >/dev/null 2>&1; then
    echo "$NAME already exists, skipping"
    continue
  fi
  echo "Creating $NAME..."
  sudo qemu-img create -f qcow2 -b "$BASE_IMG" "$DISK" 20G
  sudo virt-install \
    --name "$NAME" \
    --memory "$RAM_MB" \
    --vcpus "$VCPUS" \
    --disk path="$DISK",format=qcow2 \
    --os-variant generic \
    --import \
    --network network="$NET" \
    --cloud-init "$SEED" \
    --noautoconsole
done

echo "Current VMs:"
virsh list --all
```

- Build the seed once: `cloud-localds /var/lib/libvirt/images/seed.iso cloud-init.yml`.
- Adjust `NET`, `RAM_MB`, `VCPUS`, `COUNT`, and base/seed paths to taste.
- Replace `br0-net` with `default` if you prefer NAT.***

## Port map pattern (host → rails)
Example DNAT from external IP to each rail’s `:4433`:
```
external 4400 -> rail0 192.168.122.101:4433
external 4401 -> rail1 192.168.122.102:4433
external 4402 -> rail2 192.168.122.103:4433
external 4403 -> rail3 192.168.122.104:4433
external 4404 -> rail4 192.168.122.105:4433
external 4405 -> rail5 192.168.122.106:4433
external 4406 -> rail6 192.168.122.107:4433
external 4407 -> rail7 192.168.122.108:4433
```
With libvirt default NAT, set host forwarding via iptables/nftables. With bridged `br0-net`, you can also hit VMs directly if your LAN allows it.
