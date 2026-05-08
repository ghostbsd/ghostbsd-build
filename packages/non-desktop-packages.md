# Non-Desktop Packages Removed from packages/base

Packages identified as server-only, datacenter-specific, legacy, or not typically needed for a desktop OS.
These were removed from both `packages/base` and `packages/vital/base`.

## Server / Enterprise Only

| Package | Purpose | Status |
|---------|---------|--------|
| `GhostBSD-audit` | Security event auditing — enterprise/server compliance | Removed |
| `GhostBSD-audit-lib32` | Security audit library (32-bit) | Removed |
| `GhostBSD-autofs` | Auto-mounting NFS shares — gvfs handles media on desktop | Removed |
| `GhostBSD-bsnmp` | SNMP daemon — server/network monitoring | Removed |
| `GhostBSD-bsnmp-lib32` | SNMP library (32-bit) | Removed |
| `GhostBSD-hast` | Highly Available Storage — server clustering/replication | Removed |
| `GhostBSD-inetd` | Internet super-server daemon | Removed |
| `GhostBSD-kerberos` | Kerberos authentication tools — enterprise/AD | Removed |
| `GhostBSD-kerberos-lib` | Kerberos library | Removed (from vital) |
| `GhostBSD-nuageinit` | Cloud-init equivalent — cloud/server provisioning | Removed |
| `GhostBSD-quotacheck` | Disk quota enforcement — multi-user servers | Removed |
| `GhostBSD-rdma` | Remote Direct Memory Access — HPC/datacenter | Removed |
| `GhostBSD-librpcsec_gss` | GSS-API security for RPC — Kerberized NFS | Removed |
| `GhostBSD-librpcsec_gss-lib32` | GSS-API security for RPC (32-bit) | Removed |
| `GhostBSD-yp` | NIS/Yellow Pages — legacy directory service | Removed |

## Datacenter / Specialized Hardware

| Package | Purpose | Status |
|---------|---------|--------|
| `GhostBSD-cxgbe-tools` | Chelsio 10/25/100GbE adapter tools — datacenter NICs | Removed |
| `GhostBSD-mlx-tools` | Mellanox/NVIDIA ConnectX adapter tools — datacenter NICs | Removed |
| `GhostBSD-librss` | Receive Side Scaling library — server network optimization | Removed |
| `GhostBSD-librss-lib32` | Receive Side Scaling library (32-bit) | Removed |
| `GhostBSD-netmap` | High-performance packet I/O — server/appliance networking | Removed |
| `GhostBSD-netmap-lib32` | High-performance packet I/O (32-bit) | Removed |

## Legacy / Obsolete for Desktop

| Package | Purpose | Status |
|---------|---------|--------|
| `GhostBSD-apm` | Advanced Power Management — replaced by ACPI on modern hardware | Removed |
| `GhostBSD-at` | One-time job scheduling — rarely used on desktop | Removed |
| `GhostBSD-rcmds` | Remote commands (rsh, rlogin, rcp) — insecure, replaced by SSH | Removed |
| `GhostBSD-ftp` | FTP client — mostly superseded by fetch/curl/SFTP | Removed |
| `GhostBSD-ppp` | Point-to-Point Protocol — installed as bluetooth dependency when needed | Removed |
| `GhostBSD-natd` | NAT daemon — installed as ppp dependency when needed | Removed |
| `GhostBSD-natd-lib32` | NAT daemon library (32-bit) | Removed |

## Redundant (GhostBSD uses ipfw)

| Package | Purpose | Status |
|---------|---------|--------|
| `GhostBSD-ipf` | IP Filter firewall — redundant, GhostBSD uses ipfw | Removed |

## Debug / Tracing Tools

| Package | Purpose | Status |
|---------|---------|--------|
| `GhostBSD-ctf` | Compact C Type Format — DTrace debug info | Removed |
| `GhostBSD-dtrace` | System tracing/profiling | Removed |
| `GhostBSD-dtrace-lib32` | System tracing (32-bit) | Removed |
| `GhostBSD-dwatch` | DTrace script wrapper | Removed |
| `GhostBSD-lldb` | LLVM debugger | Removed |

## VM / Hypervisor (installed as dependencies when needed)

| Package | Purpose | Status |
|---------|---------|--------|
| `GhostBSD-lib9p` | 9P protocol — bhyve pulls it in as dependency | Removed |
| `GhostBSD-lib9p-lib32` | 9P protocol (32-bit) | Removed |
| `GhostBSD-libvmmapi` | VM Monitor API — bhyve pulls it in as dependency | Removed |

## Storage Tools

| Package | Purpose | Status |
|---------|---------|--------|
| `GhostBSD-ccdconfig` | Concatenated disk config — legacy, ZFS/GEOM replaces it | Removed |
| `GhostBSD-ggate` | GEOM gate network block device — SAN/server | Removed |

## Other lib32 Removed

| Package | Purpose | Status |
|---------|---------|--------|
| `GhostBSD-bluetooth-lib32` | Bluetooth (32-bit) — no 32-bit bluetooth apps | Removed |
| `GhostBSD-libcuse-lib32` | Userspace char device (32-bit) | Removed |
| `GhostBSD-libvgl-lib32` | Obsolete VGA library (32-bit) | Removed |
| `GhostBSD-zfs-lib32` | ZFS library (32-bit) — no 32-bit app needs ZFS | Removed |

## Kept (decided to keep despite being non-desktop)

| Package | Purpose | Reason |
|---------|---------|--------|
| `GhostBSD-hyperv-tools` | Hyper-V VM guest tools | Needed to run GhostBSD on Hyper-V |
| `GhostBSD-hostapd` | Wi-Fi AP daemon | Useful for desktop users creating hotspots |
| `GhostBSD-acct` | Process accounting | Provides `last` and `users` commands |

## Added

| Package | Purpose |
|---------|---------|
| `GhostBSD-ntp` | NTP daemon — needed for `ntpd_enable="YES"` in rc config |