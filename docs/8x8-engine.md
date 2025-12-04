# 8×8 Engine Pattern (Ω rails)

Definition: one public IP fronts eight Clear Linux VMs (rail0…rail7). Each rail has 8 vCPUs and 8 GB RAM running a Rust Ω engine (phi physics, mining, audio, etc.). Total per engine: 64 vCPUs / 64 GB Ω compute.

Lore phrasing: “One star. 8 rails. Each rail has 8 cores of attention and 8 gigs of memory. Together they’re a 64-core Ω engine behind one IP.”

## Host shape
- KVM host (Debian/Ubuntu) with libvirt; holds the static IP and DNAT/bridge rules.
- Capacity target: ~64 vCPUs / 64 GB for guests plus headroom (aim ~96 GB RAM; modest CPU overcommit acceptable if not all rails are hot).

## Guests (rails)
- Names: engine0…engine7.
- OS: Clear Linux.
- Spec: `--vcpus 8`, `--memory 8192`.
- Service: `omega-engine.service` listening on `0.0.0.0:4433`.

## Port map (host → rails)
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
With NAT, set host DNAT (iptables/nftables). With bridge, you can also hit the VMs directly if LAN permits.

## Client wiring
- Paper plugin: choose `rail_index = hash(phone+label) mod 8`; send to `ENGINE_IP:(4400+rail_index)`; host routes to the rail’s Ω engine.
- Rails call out to Cloud Run (`dlog-api`, `omega-fs-writer`) and tag `rail_id` as needed.

## Optional rail roles
- Symmetric by default.
- Flavoring example: 0–3 game physics/mining, 4 audio/flame, 5 land/oracle, 6 backing metrics, 7 canary/dev. Same Clear+Rust stack; configs differ.
