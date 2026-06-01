# scripts/build_ad_list.ps1
# Reads an ad-rule .conf, dedupes, drops DGA-looking domains, and writes
# ad_list.txt in Shadowrocket RULE-SET format (one rule per line, plus a
# 4-line comment header). UTF-8 no BOM. Design: see ../2026-06-01-shadowrocket-config-repo-design.md §7.
[CmdletBinding()]
param(
    [string]$InputPath  = (Join-Path $PSScriptRoot '..\src\sr_ad_only.conf'),
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\ad_list.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Update-TypeData -TypeName System.String -MemberName Count -MemberType ScriptProperty -Value { 1 } -Force

$CheapTlds = @('online','site','space','store','website','rest','top','xyz','click')

function Test-IsDgaDomain {
    param([Parameter(Mandatory)][string]$Rule)
    # Only filter DOMAIN-SUFFIX rules; IP-CIDR is left alone (design §7).
    if ($Rule -notmatch '^DOMAIN-SUFFIX,') { return $false }
    $parts = $Rule.Split(',')
    if ($parts.Count -lt 2) { return $false }
    $fqdn  = $parts[1].Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($fqdn)) { return $false }

    $labels = $fqdn.Split('.')
    if ($labels.Count -lt 2) { return $true }                                # 7a: no dot → noise
    $sld = $labels[-2]                                                       # second-level domain
    $tld = $labels[-1]

    # 7b: long SLD, no vowels, single cheap TLD
    if ($sld.Length -gt 14 -and $sld -notmatch '[aeiou]' -and $CheapTlds -contains $tld) {
        return $true
    }
    # 7c: 14+ chars, all lowercase, no hyphen → very DGA-like
    if ($sld.Length -ge 14 -and $sld -cmatch '^[a-z]{14,}$') {
        return $true
    }
    return $false
}

function Invoke-BuildAdList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InputPath,
        [Parameter(Mandatory)][string]$OutputPath
    )
    if (-not (Test-Path -LiteralPath $InputPath)) {
        throw "Input file not found: $InputPath"
    }

    $raw    = Get-Content -LiteralPath $InputPath -Encoding utf8
    $seen   = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $kept   = New-Object System.Collections.Generic.List[string]

    foreach ($line in $raw) {
        $trim = $line.TrimEnd()
        if ([string]::IsNullOrWhiteSpace($trim))      { continue }
        if ($trim.StartsWith('#'))                     { continue }   # comments + # keep: marker
        if ($trim.StartsWith('['))                     { continue }   # [General] / [Rule] / etc.
        # Normalize: collapse spaces around the commas
        $norm = ($trim -split '\s*,\s*') -join ','
        if ($norm.StartsWith('#'))                     { continue }   # safety after normalization
        if (Test-IsDgaDomain $norm)                    { continue }
        if (-not $seen.Add($norm))                     { continue }   # dedup
        $kept.Add($norm) | Out-Null
    }

    $ruleCount = $kept.Count
    $tsUtc     = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

    $header = @(
        '# ad_list.txt'
        "# Source: $InputPath"
        "# Built: $tsUtc"
        "# Rule count: $ruleCount"
    )

    $dir = Split-Path -Parent $OutputPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($OutputPath, ($header + $kept), $utf8NoBom)
}

# Allow direct invocation: pwsh ./scripts/build_ad_list.ps1
if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.MyCommand.Path -eq $PSCommandPath) {
    Invoke-BuildAdList -InputPath $InputPath -OutputPath $OutputPath
    Write-Host ("Wrote {0} rules to {1}" -f (Get-Content $OutputPath | Where-Object { $_ -notmatch '^\s*#' }).Count, $OutputPath)
}