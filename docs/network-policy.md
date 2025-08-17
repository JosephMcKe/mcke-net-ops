# Network & Security Policy

## VLANs & addressing
- LAN (1): 192.168.1.0/24 – HAL .11, Marvin .12, NAS .13, Printer .24
- IoT (2): 192.168.2.0/24 – TVs .104/.105 (allowlist to Jellyfin only)
- Guest (3): 192.168.3.0/24 – internet only

## DNS/mDNS
- DNS on Edge; internal zones `mcke.lan`, `mcke.iot`, `mcke.gst`.
- mDNS (Bonjour Gateway) **LAN↔IoT only**, allowlist `_ipp._tcp`, `_ipps._tcp`.
- Printer is on LAN (AirPrint via IPP 631/tcp).

## NTP
- chrony on Marvin (192.168.1.12). DHCP option 42 → Marvin. Block WAN NTP for others.

## Firewall rules (summary)
| # | From | To | Port(s) | Action | Why |
|---|---|---|---|---|---|
| 1 | LAN (HAL/Marvin) | NAS | 111,2049,445 TCP/UDP | ALLOW | NFS/SMB mounts |
| 2 | All VLANs | Marvin (NTP) | 123/UDP | ALLOW | Time source |
| 3 | Any≠Marvin | WAN | 123/UDP | DENY | Block random NTP |
| 4 | IoT | LAN | any | DENY | Isolation |
| 5a | 192.168.2.104 | 192.168.1.11 | 443/TCP | ALLOW | TV → Jellyfin |
| 5b | 192.168.2.105 | 192.168.1.11 | 443/TCP | ALLOW | FireTV → Jellyfin |
| 6 | Guest | LAN/IoT | any | DENY | Guest isolation |
| 7 | VPN | LAN | required only | ALLOW | Admin access |
| 8 | Any | Any | any | DENY | Default drop |

## LAN-open routes
- Homepage (read-only), Jellyfin (in-app auth; no self-register/remote), Calibre-Web (view-only), Tandoor (view-only), Kiwix (read-only).  
All restricted to **LAN-only** at ingress (IP allowlist). Admin paths still require login.
