# scripts/build_ad_list.Tests.ps1
BeforeAll {
    $script:Script = Join-Path $PSScriptRoot 'build_ad_list.ps1'
    . $script:Script   # dot-source will FAIL until Task 8 implements the script
}

Describe 'build_ad_list.ps1' {
    BeforeAll {
        $script:TempDir  = Join-Path ([System.IO.Path]::GetTempPath()) ("bal_test_" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:TempDir | Out-Null
    }
    AfterAll {
        Remove-Item -Recurse -Force $script:TempDir
    }

    Context 'Deduplication' {
        It 'collapses identical rules' {
            $in  = Join-Path $script:TempDir 'in.txt'
            $out = Join-Path $script:TempDir 'out.txt'
            @(
                'DOMAIN-SUFFIX,a.example.com,Reject'
                'DOMAIN-SUFFIX,a.example.com,Reject'
                'DOMAIN-SUFFIX,b.example.com,Reject'
            ) | Set-Content -Path $in -Encoding utf8NoBOM
            Invoke-BuildAdList -InputPath $in -OutputPath $out
            (Get-Content $out | Where-Object { $_ -notmatch '^\s*#' }).Count | Should -Be 2
        }
    }

    Context 'DGA filter' {
        It 'drops single-label (no dot) SLDs' {
            $in  = Join-Path $script:TempDir 'in.txt'
            $out = Join-Path $script:TempDir 'out.txt'
            'DOMAIN-SUFFIX,nodot,Reject' | Set-Content -Path $in -Encoding utf8NoBOM
            Invoke-BuildAdList -InputPath $in -OutputPath $out
            Get-Content $out | Where-Object { $_ -match 'DOMAIN-SUFFIX' } | Should -BeNullOrEmpty
        }

        It 'drops long no-vowel SLD on cheap TLD' {
            $in  = Join-Path $script:TempDir 'in.txt'
            $out = Join-Path $script:TempDir 'out.txt'
            'DOMAIN-SUFFIX,qwrtpsdfgkjlnm.online,Reject' | Set-Content -Path $in -Encoding utf8NoBOM
            Invoke-BuildAdList -InputPath $in -OutputPath $out
            Get-Content $out | Where-Object { $_ -match 'DOMAIN-SUFFIX' } | Should -BeNullOrEmpty
        }

        It 'drops long all-lowercase no-hyphen SLD' {
            $in  = Join-Path $script:TempDir 'in.txt'
            $out = Join-Path $script:TempDir 'out.txt'
            'DOMAIN-SUFFIX,abcdefghijklmnopqrstuvwxyz.com,Reject' | Set-Content -Path $in -Encoding utf8NoBOM
            Invoke-BuildAdList -InputPath $in -OutputPath $out
            Get-Content $out | Where-Object { $_ -match 'DOMAIN-SUFFIX' } | Should -BeNullOrEmpty
        }

        It 'keeps a normal domain like cdn.jsdelivr.net' {
            $in  = Join-Path $script:TempDir 'in.txt'
            $out = Join-Path $script:TempDir 'out.txt'
            'DOMAIN-SUFFIX,cdn.jsdelivr.net,Reject' | Set-Content -Path $in -Encoding utf8NoBOM
            Invoke-BuildAdList -InputPath $in -OutputPath $out
            Get-Content $out | Where-Object { $_ -match 'DOMAIN-SUFFIX' } | Should -HaveCount 1
        }
    }

    Context 'Header generation' {
        It 'writes 4 comment header lines including rule count + UTC timestamp' {
            $in  = Join-Path $script:TempDir 'in.txt'
            $out = Join-Path $script:TempDir 'out.txt'
            'DOMAIN-SUFFIX,a.example.com,Reject' | Set-Content -Path $in -Encoding utf8NoBOM
            Invoke-BuildAdList -InputPath $in -OutputPath $out
            $lines = Get-Content $out
            $lines[0] | Should -Match '^# ad_list\.txt'
            $lines[1] | Should -Match '^# (Source|来源):'
            $lines[2] | Should -Match '^# (Built|构建):'
            $lines[3] | Should -Match '^# (Rule count|规则数): 1$'
        }
    }

    Context 'Action field stripping' {
        It 'strips Reject/REJECT/DIRECT/PROXY from 3-field rules' {
            $in  = Join-Path $script:TempDir 'in.txt'
            $out = Join-Path $script:TempDir 'out.txt'
            @(
                'DOMAIN-SUFFIX,ad.example.com,Reject'
                'DOMAIN-SUFFIX,bad.com,REJECT'
                'DOMAIN-SUFFIX,ok.com,DIRECT'
                'DOMAIN-SUFFIX,go.com,PROXY'
            ) | Set-Content -Path $in -Encoding utf8NoBOM
            Invoke-BuildAdList -InputPath $in -OutputPath $out
            $rules = Get-Content $out | Where-Object { $_ -notmatch '^\s*#' }
            $rules | Should -HaveCount 4
            foreach ($r in $rules) {
                ($r.Split(',').Count) | Should -Be 2
            }
        }
    }

    Context 'IP-CIDR filtering' {
        It 'drops IP-CIDR rules' {
            $in  = Join-Path $script:TempDir 'in.txt'
            $out = Join-Path $script:TempDir 'out.txt'
            @(
                'DOMAIN-SUFFIX,ad.example.com,Reject'
                'IP-CIDR,192.168.1.0/24,Reject'
                'IP-CIDR,10.0.0.0/8,Reject'
                'DOMAIN-SUFFIX,tracker.example.net,Reject'
            ) | Set-Content -Path $in -Encoding utf8NoBOM
            Invoke-BuildAdList -InputPath $in -OutputPath $out
            $rules = Get-Content $out | Where-Object { $_ -notmatch '^\s*#' }
            $rules | Should -HaveCount 2
            $rules | Where-Object { $_ -match 'IP-CIDR' } | Should -BeNullOrEmpty
        }
    }

    Context 'Input filtering' {
        It 'skips empty, comment, and section header lines' {
            $in  = Join-Path $script:TempDir 'in.txt'
            $out = Join-Path $script:TempDir 'out.txt'
            @(
                ''
                '# a comment'
                '[General]'
                'DOMAIN-SUFFIX,keep.example.com,Reject'
                '   '
                '  '
            ) | Set-Content -Path $in -Encoding utf8NoBOM
            Invoke-BuildAdList -InputPath $in -OutputPath $out
            (Get-Content $out | Where-Object { $_ -match 'DOMAIN-SUFFIX' }).Count | Should -Be 1
        }
    }
}