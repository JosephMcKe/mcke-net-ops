# Firewall Rules (UCG Ultra)

- Default: deny inter-VLAN. Guest internet-only.
- Allow NFS/SMB LAN→NAS; NTP to Marvin; block WAN NTP for others.
- IoT TVs allow to HAL:443 only (Jellyfin).
- Printer is LAN-resident (no IoT access required).
