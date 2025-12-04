# DNS Zones Plan (dlog.gold)

Use these commands in your GCP project to create and manage the zones and records.

## Zones
- Public: `dlog-gold-zone` (`dlog.gold.`), visibility public.
- Private: `internal-dlog-zone` (`internal.dlog.`), visibility private, network `dlog-vpc`.
- Reverse private: `reverse-10-0-zone` (`0.10.in-addr.arpa.`), visibility private, network `dlog-vpc`.

## Create zones
```bash
# Public
gcloud dns managed-zones create dlog-gold-zone \
  --description="Public zone for dlog.gold" \
  --dns-name=dlog.gold. \
  --visibility=public

# Private internal
gcloud dns managed-zones create internal-dlog-zone \
  --description="Private zone for internal.dlog" \
  --dns-name=internal.dlog. \
  --visibility=private \
  --networks=dlog-vpc

# Reverse for 10.0.0.0/16
gcloud dns managed-zones create reverse-10-0-zone \
  --description="Reverse DNS for 10.0.0.0/16" \
  --dns-name=0.10.in-addr.arpa. \
  --visibility=private \
  --networks=dlog-vpc
```

## Public records (example, TTL 30s)
For `dlog-gold-public` (DNSSEC on, logging off). Replace with the correct zone name if needed.
```bash
ZONE=dlog-gold-public

# Ensure zone exists
gcloud dns managed-zones create "$ZONE" \
  --dns-name=dlog.gold. \
  --visibility=public \
  --dnssec-state=on \
  --description="Public zone for dlog.gold" \
  --labels=env=prod

gcloud dns record-sets transaction start --zone="$ZONE"

# SOA/NS (usually managed automatically; included here for completeness)
gcloud dns record-sets transaction add \
  "ns-cloud-b1.googledomains.com. cloud-dns-hostmaster.google.com. 6 21600 3600 259200 300" \
  --name=dlog.gold. --ttl=1 --type=SOA --zone="$ZONE"

gcloud dns record-sets transaction add \
  "ns-cloud-b1.googledomains.com." \
  "ns-cloud-b2.googledomains.com." \
  "ns-cloud-b3.googledomains.com." \
  "ns-cloud-b4.googledomains.com." \
  --name=dlog.gold. --ttl=8 --type=NS --zone="$ZONE"

# Apex A
gcloud dns record-sets transaction add 34.26.6.76 \
  --name=dlog.gold. --ttl=1 --type=A --zone="$ZONE"

# Verification TXT
gcloud dns record-sets transaction add "google-site-verification=EXrS59hSKlZcxQTrJO6jJVV1Aey_W2r0TKgIgtoRbeg" \
  --name=dlog.gold. --ttl=8 --type=TXT --zone="$ZONE"

# Minecraft SRV
gcloud dns record-sets transaction add "0 5 25565 mc.dlog.gold." \
  --name=_minecraft._tcp.dlog.gold. --ttl=1 --type=SRV --zone="$ZONE"

# CNAME for API
gcloud dns record-sets transaction add ghs.googlehosted.com. \
  --name=api.dlog.gold. --ttl=1 --type=CNAME --zone="$ZONE"

# MC A records (8 rails)
gcloud dns record-sets transaction add \
  34.138.180.68 \
  104.196.206.122 \
  34.26.186.252 \
  104.196.42.247 \
  35.229.25.192 \
  34.148.54.150 \
  34.148.48.238 \
  35.231.190.255 \
  --name=mc.dlog.gold. --ttl=1 --type=A --zone="$ZONE"

# Extra A records
gcloud dns record-sets transaction add 216.239.38.21 \
  --name=first.dlog.gold. --ttl=8 --type=A --zone="$ZONE"

gcloud dns record-sets transaction add 216.239.32.21 \
  --name=fifth.dlog.gold. --ttl=1 --type=A --zone="$ZONE"

gcloud dns record-sets transaction execute --zone="$ZONE"
```

## Internal records (example, TTL 1s)
Replace IPs with your 10.0.x.x hosts.
```bash
gcloud dns record-sets transaction start --zone=internal-dlog-zone
for i in $(seq 0 7); do
  gcloud dns record-sets transaction add 10.0.0.$((101+i)) \
    --name=engine${i}.internal.dlog. --ttl=1 --type=A --zone=internal-dlog-zone
done
gcloud dns record-sets transaction add 10.0.0.50 \
  --name=omega.internal.dlog. --ttl=1 --type=A --zone=internal-dlog-zone
gcloud dns record-sets transaction execute --zone=internal-dlog-zone
```

## Reverse PTR records (example, TTL 8s)
Match the A records above.
```bash
gcloud dns record-sets transaction start --zone=reverse-10-0-zone
for i in $(seq 0 7); do
  gcloud dns record-sets transaction add engine${i}.internal.dlog. \
    --name=$((101+i)).0.10.in-addr.arpa. --ttl=8 --type=PTR --zone=reverse-10-0-zone
done
gcloud dns record-sets transaction add omega.internal.dlog. \
  --name=50.0.10.in-addr.arpa. --ttl=8 --type=PTR --zone=reverse-10-0-zone
gcloud dns record-sets transaction execute --zone=reverse-10-0-zone
```
