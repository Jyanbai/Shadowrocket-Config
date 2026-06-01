# Changelog

All notable changes to this repo are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.2.0] - 2026-06-01

### Fixed
- DNS leak: changed `dns-server` from `system` → `223.5.5.5,119.29.29.29` (Alidns + TencentDNS IP); previous DoH format was silently ignored by Shadowrocket.
- DNS leak: removed `ChinaCompanyIp.list` and `ChinaIp.list` RULE-SETs (IP-CIDR rules force local DNS resolution in rule mode, causing leaks).
- DNS leak: removed all 128 IP-CIDR rules from `ad_list.txt` (same reason; pure DOMAIN-SUFFIX list avoids unnecessary DNS lookups).

### Smoke test - 2026-06-01
- iOS Shadowrocket subscription: OK
- Domestic sites (zhihu, baidu): DIRECT, fast
- International sites (google): PROXY, works
- Ad blocking: verified via ad.12306.cn and ad.doubleclick.net (REJECT)
- DNS leak: dnsleaktest.com shows no ISP DNS servers leaking

## [0.1.0] - 2026-06-01

### Added
- Initial `Shadowrocket.conf` with proxy routing + DNS leak protection.
- CDN whitelist (`cdnjs.cloudflare.com`, `cdn.jsdelivr.net`, `cdn.bootcdn.net`, `unpkg.com`) ahead of ad RULE-SET to prevent IP-CIDR over-blocking.
- Custom `RULE-SET` referencing repo's own `ad_list.txt` (replaces ACL4SSR's `BanAD.list` / `BanProgramAD.list`).
- `scripts/build_ad_list.ps1` to generate `ad_list.txt` from archived `src/sr_ad_only.conf` (dedup + DGA filter).
- Pester test suite for the build script.
- Immutable archive `src/sr_ad_only.conf` (64,838 lines; DGA-heavy).

### Notes
- ad_list size: see top-of-file comment after first `pwsh ./scripts/build_ad_list.ps1` run.
- Subscription URL: https://raw.githubusercontent.com/Jyanbai/Shadowrocket-Config/main/Shadowrocket.conf