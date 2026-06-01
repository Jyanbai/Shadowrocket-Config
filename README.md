# Shadowrocket Config

Personal Shadowrocket configuration published as a single subscription URL. Combines proxy routing and ad blocking. Optimized for iOS Shadowrocket; no other proxy cores are supported.

## Subscription

```
https://raw.githubusercontent.com/Jyanbai/Shadowrocket-Config/main/Shadowrocket.conf
```

In iOS Shadowrocket: **设置 → 配置文件 → 从 URL 下载**, paste the URL above, then tap **立即更新**. For auto-refresh, enable **设置 → 通用 → 自动更新 → 1440 分钟** (24 h).

If `raw.githubusercontent.com` is unreachable from your network, use the jsDelivr mirror:

```
https://cdn.jsdelivr.net/gh/Jyanbai/Shadowrocket-Config@main/Shadowrocket.conf
```

## What's in the box

| File | Purpose |
|---|---|
| `Shadowrocket.conf` | The single subscription file iOS reads. |
| `ad_list.txt` | Cleaned ad rule list referenced by the conf's `RULE-SET`. |
| `src/sr_ad_only.conf` | Immutable archive of the original input. Don't edit. |
| `scripts/build_ad_list.ps1` | Regenerates `ad_list.txt` from the archive. |
| `scripts/build_ad_list.Tests.ps1` | Pester tests for the build script. |
| `LICENSE` | MIT. |
| `CHANGELOG.md` | History of structural / size changes. |

## Maintenance

To update the ad list after editing `src/sr_ad_only.conf`:

```bash
pwsh ./scripts/build_ad_list.ps1
git add ad_list.txt
git commit -m "chore(ad_list): refresh"
git push
```

To prevent a specific rule from being filtered as DGA, place a `# keep:` line directly above it in `src/sr_ad_only.conf`.

## Design

See [`2026-06-01-shadowrocket-config-repo-design.md`](../2026-06-01-shadowrocket-config-repo-design.md) for the full design rationale (data flow, DGA filter rules, validation, error handling).