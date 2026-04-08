param(
    [string]$Query = "",
    [int]$Top = 8,
    [switch]$List
)

$ErrorActionPreference = "Stop"

$SkillRoot = Split-Path -Parent $PSScriptRoot
$SkillsRoot = Split-Path -Parent $SkillRoot
$CodexHomeFromSkill = Split-Path -Parent $SkillsRoot

function Resolve-LibraryRoot {
    $candidates = New-Object System.Collections.Generic.List[string]

    if ($env:CODEX_HOME) {
        $candidates.Add((Join-Path $env:CODEX_HOME "awesome-design-md"))
    }

    $candidates.Add((Join-Path $HOME ".codex\\awesome-design-md"))
    $candidates.Add((Join-Path $CodexHomeFromSkill "awesome-design-md"))
    $repoParent = Split-Path -Parent $SkillsRoot
    if ($repoParent) {
        $candidates.Add((Join-Path $repoParent "awesome-design-md"))
    }

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (Test-Path (Join-Path $candidate "README.md")) {
            return $candidate
        }
    }

    $checked = ($candidates | Select-Object -Unique) -join "; "
    throw "awesome-design-md not found. Checked: $checked"
}

$RepoRoot = Resolve-LibraryRoot
$ReadmePath = Join-Path $RepoRoot "README.md"
$DesignRoot = Join-Path $RepoRoot "design-md"

function Get-LibraryEntries {
    $category = ""
    $entries = New-Object System.Collections.Generic.List[object]

    foreach ($line in Get-Content $ReadmePath) {
        if ($line -match '^###\s+(.+)$') {
            $category = $Matches[1].Trim()
            continue
        }

        if ($line -match '^- \[\*\*(.+?)\*\*\]\(.+?/design-md/([^/]+)/\) - (.+)$') {
            $name = $Matches[1].Trim()
            $slug = $Matches[2].Trim()
            $description = $Matches[3].Trim()
            $designPath = Join-Path (Join-Path $DesignRoot $slug) "DESIGN.md"
            $previewPath = Join-Path (Join-Path $DesignRoot $slug) "preview.html"
            $previewDarkPath = Join-Path (Join-Path $DesignRoot $slug) "preview-dark.html"

            $entries.Add([pscustomobject]@{
                Name = $name
                Slug = $slug
                Category = $category
                Description = $description
                DesignPath = $designPath
                PreviewPath = $previewPath
                PreviewDarkPath = $previewDarkPath
            })
        }
    }

    return $entries
}

function Expand-QueryTokens {
    param([string]$RawQuery)

    $aliasMap = @{
        "minimal" = @("minimalist", "clean", "simple", "stark", "airy")
        "editorial" = @("magazine", "serif", "reading", "content")
        "developer" = @("docs", "terminal", "code", "platform")
        "terminal" = @("monochrome", "developer", "code")
        "dark" = @("black", "cinematic", "neon", "moody")
        "light" = @("white", "clean", "airy")
        "luxury" = @("premium", "refined", "elegant", "dramatic")
        "premium" = @("luxury", "refined", "elegant")
        "fintech" = @("banking", "payment", "trust", "institutional")
        "dashboard" = @("analytics", "data", "dense")
        "gradient" = @("vibrant", "colorful", "glow")
        "playful" = @("friendly", "soft", "colorful")
        "warm" = @("terracotta", "organic", "parchment")
        "docs" = @("documentation", "reading", "developer")
        "anthropic" = @("claude", "warm", "editorial")
        "linear" = @("linear.app", "minimal", "precise")
        "xai" = @("x.ai", "futuristic", "stark")
    }

    $tokens = @()
    foreach ($token in ($RawQuery.ToLowerInvariant() -split '[^\p{L}\p{Nd}\.\-]+')) {
        if ([string]::IsNullOrWhiteSpace($token)) {
            continue
        }

        $tokens += $token
        if ($aliasMap.ContainsKey($token)) {
            $tokens += $aliasMap[$token]
        }
    }

    return $tokens | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
}

function Get-Score {
    param(
        [object]$Entry,
        [string[]]$Tokens
    )

    $score = 0
    $slug = $Entry.Slug.ToLowerInvariant()
    $name = $Entry.Name.ToLowerInvariant()
    $category = $Entry.Category.ToLowerInvariant()
    $description = $Entry.Description.ToLowerInvariant()

    foreach ($token in $Tokens) {
        if ($slug -eq $token) {
            $score += 80
            continue
        }

        if ($name -eq $token) {
            $score += 70
            continue
        }

        if ($slug.Contains($token)) {
            $score += 40
        }

        if ($name.Contains($token)) {
            $score += 32
        }

        if ($description.Contains($token)) {
            $score += 20
        }

        if ($category.Contains($token)) {
            $score += 14
        }
    }

    return $score
}

function Write-Entry {
    param(
        [int]$Index,
        [object]$Entry
    )

    Write-Output ("{0}. {1} [{2}] | {3}" -f $Index, $Entry.Name, $Entry.Slug, $Entry.Category)
    Write-Output ("   {0}" -f $Entry.Description)
    Write-Output ("   DESIGN.md: {0}" -f $Entry.DesignPath)
}

$entries = Get-LibraryEntries

if ($entries.Count -eq 0) {
    throw "No design entries were parsed from $ReadmePath"
}

if ($List -or [string]::IsNullOrWhiteSpace($Query)) {
    Write-Output ("Library root: {0}" -f $DesignRoot)
    Write-Output ("Entries: {0}" -f $entries.Count)

    $i = 1
    foreach ($entry in ($entries | Sort-Object Category, Name | Select-Object -First $Top)) {
        Write-Entry -Index $i -Entry $entry
        $i++
    }

    exit 0
}

$tokens = Expand-QueryTokens -RawQuery $Query
$scored = foreach ($entry in $entries) {
    $score = Get-Score -Entry $entry -Tokens $tokens
    [pscustomobject]@{
        Score = $score
        Entry = $entry
    }
}

$results = $scored |
    Where-Object { $_.Score -gt 0 } |
    Sort-Object -Property @(
        @{ Expression = { $_.Score }; Descending = $true },
        @{ Expression = { $_.Entry.Name }; Descending = $false }
    )

Write-Output ("Query: {0}" -f $Query)
Write-Output ("Expanded tokens: {0}" -f (($tokens -join ", ")))

if (-not $results) {
    Write-Output ("No strong match found. Showing {0} library entries instead." -f $Top)
    $fallback = $entries | Sort-Object Category, Name | Select-Object -First $Top
    $i = 1
    foreach ($entry in $fallback) {
        Write-Entry -Index $i -Entry $entry
        $i++
    }
    exit 0
}

$i = 1
foreach ($result in ($results | Select-Object -First $Top)) {
    Write-Entry -Index $i -Entry $result.Entry
    $i++
}
