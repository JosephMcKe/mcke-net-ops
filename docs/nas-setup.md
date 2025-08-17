# DeepThought (TrueNAS) — Phase-1 Setup Runbook

> **Goal:** Bring **DeepThought (TrueNAS)** online with resilient networking, a ZFS pool of **two mirrors**, NFSv4 exports that match your container `PUID/PGID=1000`, UPS protection, and sensible snapshots—ready for HAL/Marvin to mount at `/mnt/nas`.

---

## 0) Targets (what/why)

* **IP/DNS:** `192.168.1.13` / `nas.mcke.lan`
* **Switch:** UniFi **US-8-60W** (LACP aggregate for the two 2.5G NICs)
* **Pool layout:** 2× **mirror** vdevs (4× 2 TB NVMe total); add a 3rd mirror later
* **Exports:** **NFSv4** (primary) → map all to UID/GID **1000** (matches containers)
* **Optional SMB:** Separate **drop** share for Windows (avoid mixing ACLs with NFS paths)
* **Power:** UPS (APC BR1000MS) via **NUT** (master on NAS)
* **Protection:** SMART tests, scrubs, snapshots as per policy below

---

## 1) Base install & temporary network

1. Install **TrueNAS SCALE** to internal eMMC (64 GB ok).
2. On the console wizard, set a **static** on one NIC:

   * IP `192.168.1.13/24`, GW `192.168.1.1`, DNS `192.168.1.1`.
3. Browse to `https://192.168.1.13` and log in.

> We’ll switch to **LACP** in the next step after confirming switch config.

---

## 2) LACP on switch + NAS

### On UniFi (US-8-60W)

* Devices → Switch → **select the two NAS ports** → **Aggregate**

  * **LACP:** Active
  * **Native VLAN:** LAN
  * **Allowed VLANs:** LAN (or All)
  * Apply

### On TrueNAS

* **Network → Interfaces → Add → Link Aggregation**

  * **Type:** LACP
  * **Members:** the two 2.5G NICs
  * **IPv4:** Static `192.168.1.13/24`
  * **Gateway:** `192.168.1.1`
  * **MTU:** 1500 (default)
  * Save → Apply

**Verify**

* UniFi shows LAG **Up** on both members
* TrueNAS: LAGG interface healthy
* DNS A record set (if needed) → `nas.mcke.lan` resolves
* Reach `https://nas.mcke.lan`

---

## 3) ZFS pool (two mirrors) & globals

**Storage → Pools → Create**

* **Name:** `pool`
* **Topology:**

  * **Mirror vdev 1:** NVMe0 + NVMe1
  * **Mirror vdev 2:** NVMe2 + NVMe3
* **Options:** `lz4` compression, **Autotrim ON**, **Dedup OFF** (leave **Ashift 12**)

**System-wide**

* Keep **Autotrim** enabled (good for NVMe)
* (Later in Phase-3) **NTP** can point to **Marvin** chrony; for now defaults are fine

---

## 4) Dataset layout & tunings

Create datasets under `pool` as follows:

| Dataset                 | Purpose                           | Recordsize | Compression | Atime  | Notes                             |
| ----------------------- | --------------------------------- | ---------- | ----------- | ------ | --------------------------------- |
| `pool/apps`             | App configs/state                 | 128K       | lz4         | Off    | Parent for app subdatasets        |
| `pool/apps/nextcloud`   | Nextcloud data/config             | 128K       | lz4         | Off    | (Optionally xattr=sa)             |
| `pool/apps/jellyfin`    | Jellyfin config                   | 128K       | lz4         | Off    |                                   |
| `pool/apps/photoprism`  | PhotoPrism config/indexes         | 128K       | lz4         | Off    |                                   |
| `pool/apps/paperless`   | Paperless config                  | 128K       | lz4         | Off    |                                   |
| `pool/media`            | Movies/TV/music                   | **1M**     | lz4         | Off    | Large media files                 |
| `pool/photos`           | PhotoPrism originals              | **1M**     | lz4         | Off    | Originals; thumbs live under apps |
| `pool/docs`             | Paperless consume/archive         | 128K       | lz4         | Off    | Lots of small/medium files        |
| `pool/ebooks`           | Calibre library                   | 128K       | lz4         | Off    |                                   |
| `pool/backups`          | Restic repos / exported snapshots | 128K       | lz4         | Off    |                                   |
| `pool/security-reports` | Trivy/scan outputs                | 128K       | lz4         | Off    |                                   |
| `pool/share-drop` (SMB) | Windows “drop” share (optional)   | 128K       | lz4         | **On** | Separate ACLs (SMB)               |

### Ownership / ACLs (critical)

* Create local **user** `apps` **UID 1000** and **group** `apps` **GID 1000** (Accounts → Users/Groups).
* For **all NFS-backed datasets** (everything except `share-drop`):

  * **ACL Type:** POSIX/Unix
  * **Owner:** `apps` / `apps`
  * **Apply recursively** from each dataset root

> Matches your container `PUID/PGID=1000` so NFS perms “just work”.

---

## 5) NFSv4 export (primary)

**Sharing → NFS → Add**

* **Path:** `/mnt/pool` (export parent; children inherit)
* **Mapall User/Group:** `apps` / `apps` (UID/GID 1000)
* **Networks:** `192.168.1.0/24`
* **Security:** SYS
* **NFSv4:** Enable in **Services → NFS** (v3 **off** unless needed)

**Services → NFS:** Enable & Start (auto-start on).

> Exporting the **parent** gives one mount point on hosts: `/mnt/nas`, with clean subpaths.

---

## 6) Optional SMB drop share

**Sharing → Windows (SMB) → Add**

* **Path:** `/mnt/pool/share-drop`
* **Name:** `drop`
* Apply SMB ACLs when prompted; keep guest off (unless you want it).

> Keep SMB to this **separate** path to avoid mixing SMB ACLs on NFS-used directories.

---

## 7) UPS (NUT) master on NAS

Connect the **APC BR1000MS** by USB to DeepThought.

**Services → UPS**

* **Mode:** Master
* **Driver:** `usbhid-ups`
* **Port:** `auto`
* **Shutdown mode:** On battery (or low-battery if you prefer)
* **Shutdown timer:** e.g., 300s
* (Optional later) enable **Remote Monitor** to let HAL/Marvin act as NUT clients

Start service and confirm **Status** (on-line, battery %, runtime).

---

## 8) SMART tests & scrubs

**Tasks → S.M.A.R.T. Tests**

* **Short:** Daily (staggered times)
* **Long/Extended:** Monthly

**Tasks → Scrub Tasks**

* **Pool:** `pool`
* **Schedule:** Monthly (defaults are fine)

---

## 9) Snapshots (policy)

**Tasks → Periodic Snapshot Tasks:**

* **Configs (`pool/apps`)**

  * **Every 4h**, keep **2 days** *(or Daily keep 14 if you prefer simpler)*
* **Docs/Photos (`pool/docs`, `pool/photos`)**

  * **Daily**, keep **14 days**
* **Media (`pool/media`, `pool/ebooks`)**

  * **Weekly**, keep **4 weeks** *(optional—mainly against accidental deletions)*

> Snapshots = local safety net. Off-box backups will be **restic → USB** from HAL/Marvin.

---

## 10) HAL mount & sanity checks

On **HAL**:

```bash
# Mount once
sudo mkdir -p /mnt/nas
echo "nas.mcke.lan:/pool /mnt/nas nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab
sudo mount -a
df -h | grep /mnt/nas            # expect a line showing NFS mount
```

**Permissions sanity**:

```bash
id                              # confirm user is 1000:1000, or use sudo as needed
touch /mnt/nas/apps/.perm-ok
mkdir -p /mnt/nas/media/test && echo ok > /mnt/nas/media/test/.write-ok
ls -l /mnt/nas/apps | head
```

**Expected:** no permission errors; files created successfully.

**Quick throughput (not a benchmark):**

```bash
dd if=/dev/zero of=/mnt/nas/media/testfile bs=1M count=1024 status=progress && sync
dd if=/mnt/nas/media/testfile of=/dev/null bs=1M status=progress
rm -f /mnt/nas/media/testfile
```

---

## 11) Hardening quick hits

* **Disable** unused services (AFP, iSCSI, SMB if not using, etc.)
* **SSH:** key-only auth and/or restrict by IP, or keep disabled
* **Do not mix ACLs**: keep NFS datasets POSIX; **don’t** apply SMB ACLs on them
* **Autotrim:** keep ON (NVMe)

---

## 12) Backouts (safe)

* **LACP issues:** switch the NAS back to single-NIC static IP; fix UniFi LAG → re-enable LACP
* **NFS perms wrong:** ensure **Mapall `apps:apps`**, re-apply recursive ownership on datasets, remount on hosts
* **UPS not detected:** try `usbhid-ups` (APC), confirm cable/port; adjust driver if needed

---

## What’s next

* Proceed to **Phase-1 on HAL**: mount `/mnt/nas` and bring up `compose/phase1/hal`.
* In **Phase-3**, point NAS NTP to **Marvin** (chrony), and (optionally) enable NUT **remote monitor** so HAL/Marvin can shut down gracefully on power events.
