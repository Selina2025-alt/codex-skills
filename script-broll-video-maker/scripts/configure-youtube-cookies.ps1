param(
  [string]$Workspace = (Get-Location).Path,
  [string]$CookiesPath = "",
  [string]$EnvPath = "",
  [string]$ProjectId = "youtube-cookies-config",
  [string]$ReferenceUrl = "",
  [string]$ReferenceSearchQuery = "technology documentary b-roll",
  [int]$ReferenceSearchLimit = 1,
  [switch]$ValidateOnly,
  [switch]$SkipYtDlpProbe,
  [switch]$RequireSuccess
)

$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Utf8File {
  param([string]$Path, [string]$Text)
  $dir = Split-Path -Parent $Path
  if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Write-Json {
  param([object]$Value, [string]$Path, [int]$Depth = 10)
  Write-Utf8File -Path $Path -Text ($Value | ConvertTo-Json -Depth $Depth)
}

function Get-DotEnvValue {
  param([string[]]$Paths, [string]$Key)
  foreach ($path in $Paths) {
    if (!$path -or !(Test-Path -LiteralPath $path)) { continue }
    foreach ($line in [System.IO.File]::ReadAllLines($path)) {
      $trimmed = $line.Trim()
      if (!$trimmed -or $trimmed.StartsWith("#")) { continue }
      if ($trimmed.StartsWith("export ")) { $trimmed = $trimmed.Substring(7).Trim() }
      if ($trimmed -match "^$([regex]::Escape($Key))\s*=\s*(.*)$") {
        $value = $Matches[1].Trim()
        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
          $value = $value.Substring(1, $value.Length - 2)
        }
        if ($value) { return $value }
      }
    }
  }
  return ""
}

function Set-DotEnvValue {
  param(
    [string]$Path,
    [hashtable]$Values
  )
  $lines = @()
  if (Test-Path -LiteralPath $Path) {
    $lines = @([System.IO.File]::ReadAllLines($Path))
  }
  $seen = @{}
  $newLines = @()
  foreach ($line in $lines) {
    $trimmed = $line.Trim()
    $matched = $false
    foreach ($key in $Values.Keys) {
      if ($trimmed -match "^(export\s+)?$([regex]::Escape($key))\s*=") {
        $value = [string]$Values[$key]
        $escaped = $value.Replace('"', '\"')
        $newLines += "$key=""$escaped"""
        $seen[$key] = $true
        $matched = $true
        break
      }
    }
    if (!$matched) { $newLines += $line }
  }
  foreach ($key in $Values.Keys) {
    if (!$seen.ContainsKey($key)) {
      $value = [string]$Values[$key]
      $escaped = $value.Replace('"', '\"')
      $newLines += "$key=""$escaped"""
    }
  }
  Write-Utf8File -Path $Path -Text ($newLines -join "`r`n")
}

function Test-NetscapeCookieLine {
  param([string]$Line)
  if (!$Line -or $Line.StartsWith("#")) { return $false }
  $parts = $Line -split "`t"
  return ($parts.Count -ge 7)
}

function Test-YoutubeCookiesFile {
  param([string]$Path)
  $resolved = (Resolve-Path -LiteralPath $Path).Path
  $lines = [System.IO.File]::ReadAllLines($resolved)
  $cookieLines = @($lines | Where-Object { Test-NetscapeCookieLine $_ })
  $nowUnix = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
  $domainCounts = @{
    youtube = 0
    google = 0
    other = 0
  }
  $expired = 0
  $session = 0
  foreach ($line in $cookieLines) {
    $parts = $line -split "`t"
    $domain = $parts[0]
    $expiry = 0
    [void][int64]::TryParse($parts[4], [ref]$expiry)
    if ($domain -match "youtube\.com|youtube-nocookie\.com") {
      $domainCounts.youtube += 1
    } elseif ($domain -match "google\.com") {
      $domainCounts.google += 1
    } else {
      $domainCounts.other += 1
    }
    if ($expiry -eq 0) {
      $session += 1
    } elseif ($expiry -lt $nowUnix) {
      $expired += 1
    }
  }
  $hasNetscapeHeader = @($lines | Select-Object -First 5 | Where-Object { $_ -match "Netscape HTTP Cookie File" }).Count -gt 0
  $hasYoutubeOrGoogle = ($domainCounts.youtube + $domainCounts.google) -gt 0
  $status = if ($cookieLines.Count -eq 0) {
    "invalid"
  } elseif (!$hasYoutubeOrGoogle) {
    "warning-no-youtube-domain"
  } else {
    "valid"
  }
  return [pscustomobject]@{
    status = $status
    path = $resolved
    exists = $true
    length_bytes = (Get-Item -LiteralPath $resolved).Length
    has_netscape_header = $hasNetscapeHeader
    cookie_count = $cookieLines.Count
    youtube_cookie_count = $domainCounts.youtube
    google_cookie_count = $domainCounts.google
    other_cookie_count = $domainCounts.other
    expired_cookie_count = $expired
    session_cookie_count = $session
  }
}

$workspacePath = (Resolve-Path -LiteralPath $Workspace).Path
if (!$EnvPath) { $EnvPath = Join-Path $workspacePath ".env" }
if (![System.IO.Path]::IsPathRooted($EnvPath)) { $EnvPath = Join-Path $workspacePath $EnvPath }

$dotenvPaths = @(
  $EnvPath,
  (Join-Path $env:USERPROFILE ".codex\.env"),
  (Join-Path $env:USERPROFILE ".agents\.env")
)
if (!$CookiesPath) {
  if ($env:YTDLP_COOKIES_PATH) {
    $CookiesPath = $env:YTDLP_COOKIES_PATH
  } else {
    $CookiesPath = Get-DotEnvValue -Paths $dotenvPaths -Key "YTDLP_COOKIES_PATH"
  }
}
if (!$CookiesPath) { throw "CookiesPath is required, or set YTDLP_COOKIES_PATH in .env." }
if (![System.IO.Path]::IsPathRooted($CookiesPath)) { $CookiesPath = Join-Path $workspacePath $CookiesPath }
if (!(Test-Path -LiteralPath $CookiesPath -PathType Leaf)) { throw "cookies.txt file not found: $CookiesPath" }

$projectRoot = Join-Path $workspacePath "projects\$ProjectId"
$logDir = Join-Path $projectRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$cookieValidation = Test-YoutubeCookiesFile -Path $CookiesPath
$diagnosticSummary = $null
if (!$SkipYtDlpProbe) {
  $skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
  $diagnostics = Join-Path $skillRoot "scripts\test-youtube-reference-diagnostics.ps1"
  $diagProjectId = "$ProjectId-yt-dlp"
  $args = @(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $diagnostics,
    "-Workspace", $workspacePath,
    "-ProjectId", $diagProjectId,
    "-YtDlpCookiesPath", $cookieValidation.path,
    "-ReferenceSearchQuery", $ReferenceSearchQuery,
    "-ReferenceSearchLimit", $ReferenceSearchLimit
  )
  if ($ReferenceUrl) { $args += @("-ReferenceUrl", $ReferenceUrl) }
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $diagOutput = @(powershell @args 2>&1)
    $diagExitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  $diagReportPath = Join-Path $workspacePath "projects\$diagProjectId\logs\youtube-diagnostics.json"
  $diagReport = if (Test-Path -LiteralPath $diagReportPath) {
    Get-Content -LiteralPath $diagReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
  } else {
    [pscustomobject]@{ status = "missing"; checks = @(); output = ($diagOutput -join "`n") }
  }
  $diagnosticSummary = [pscustomobject]@{
    exit_code = $diagExitCode
    status = $diagReport.status
    report = $diagReportPath
    categories = (@($diagReport.checks | Where-Object { $_.status -ne "passed" } | ForEach-Object { $_.category } | Where-Object { $_ } | Sort-Object -Unique) -join ",")
  }
}

$configured = $false
if (!$ValidateOnly) {
  Set-DotEnvValue -Path $EnvPath -Values @{
    YTDLP_COOKIES_PATH = $cookieValidation.path
    YTDLP_COOKIES_FROM_BROWSER = ""
  }
  $configured = $true
}

$status = if ($cookieValidation.status -eq "invalid") {
  "invalid"
} elseif ($diagnosticSummary -and $diagnosticSummary.status -eq "passed") {
  "ready"
} elseif ($diagnosticSummary) {
  "configured-needs-auth-check"
} else {
  "configured"
}

$reportPath = Join-Path $logDir "youtube-cookies-config.json"
$report = [pscustomobject]@{
  status = $status
  configured = $configured
  env_path = $EnvPath
  cookies = $cookieValidation
  yt_dlp_probe = $diagnosticSummary
}
Write-Json $report $reportPath 8

[pscustomobject]@{
  status = $status
  configured = $configured
  env_path = $EnvPath
  cookies_status = $cookieValidation.status
  cookie_count = $cookieValidation.cookie_count
  youtube_cookie_count = $cookieValidation.youtube_cookie_count
  google_cookie_count = $cookieValidation.google_cookie_count
  yt_dlp_status = $(if ($diagnosticSummary) { $diagnosticSummary.status } else { "skipped" })
  yt_dlp_categories = $(if ($diagnosticSummary) { $diagnosticSummary.categories } else { "" })
  report = $reportPath
} | ConvertTo-Json -Depth 5

if ($RequireSuccess -and $status -ne "ready") {
  exit 1
}
