# Changelog

All notable changes to this repo are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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