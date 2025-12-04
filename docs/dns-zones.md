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
Replace `X.X.X.X` with your IP (e.g., load balancer).
```bash
gcloud dns record-sets transaction start --zone=dlog-gold-zone
gcloud dns record-sets transaction add X.X.X.X \
  --name=api.dlog.gold. --ttl=30 --type=A --zone=dlog-gold-zone
gcloud dns record-sets transaction add X.X.X.X \
  --name=engine.dlog.gold. --ttl=30 --type=A --zone=dlog-gold-zone
gcloud dns record-sets transaction add X.X.X.X \
  --name=airdrop.dlog.gold. --ttl=30 --type=A --zone=dlog-gold-zone
gcloud dns record-sets transaction execute --zone=dlog-gold-zone
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
