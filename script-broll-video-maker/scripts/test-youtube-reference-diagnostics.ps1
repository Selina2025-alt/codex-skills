param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectId = "self-test-youtube-diagnostics",
  [string]$ReferenceUrl = "https://www.youtube.com/watch?v=BaW_jenozKc",
  [string]$ReferenceSearchQuery = "technology documentary b-roll",
  [int]$ReferenceSearchLimit = 1,
  [string]$YtDlpCookiesFromBrowser = "",
  [string]$YtDlpCookiesPath = "",
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

function Get-ToolPath {
  param([string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $localBin = Join-Path $env:USERPROFILE ".local\bin\$Name.exe"
  if (Test-Path -LiteralPath $localBin) { return $localBin }
  $workspaceTool = Join-Path (Resolve-Path -LiteralPath ".") "tools\$Name.exe"
  if (Test-Path -LiteralPath $workspaceTool) { return $workspaceTool }
  return $null
}

function Get-YtDlpFailureCategory {
  param([string]$Text)
  if ($Text -match "Could not copy Chrome cookie database") { return "cookie_copy_failed" }
  if ($Text -match "Failed to decrypt with DPAPI") { return "dpapi_decrypt_failed" }
  if ($Text -match "could not find .*cookies database" -or $Text -match "could not find .*cookie database") { return "browser_cookies_missing" }
  if ($Text -match "Sign in to confirm.*not a bot" -or $Text -match "cookies.*authentication") { return "auth_required" }
  if ($Text -match "Video unavailable") { return "video_unavailable" }
  if ($Text -match "must provide at least one URL") { return "missing_input" }
  if ($Text -match "HTTP Error 429" -or $Text -match "Too Many Requests") { return "rate_limited" }
  if ($Text -match "Unsupported URL") { return "unsupported_url" }
  if ($Text -match "Unable to download webpage" -or $Text -match "timed out" -or $Text -match "Temporary failure") { return "network_error" }
  return "unknown"
}

function Get-YtDlpFailureHint {
  param([string]$Category)
  if ($Category -eq "cookie_copy_failed") { return "yt-dlp could not copy the Chromium cookie database. Close Edge/Chrome and retry, or export cookies.txt and pass -YtDlpCookiesPath." }
  if ($Category -eq "dpapi_decrypt_failed") { return "yt-dlp found Chrome cookies but Windows DPAPI decryption failed. Export cookies.txt from the logged-in browser, try another Chrome profile, or try another browser source." }
  if ($Category -eq "browser_cookies_missing") { return "No browser cookie database was found for this browser. Log in to YouTube in that browser, or export cookies.txt and pass -YtDlpCookiesPath." }
  if ($Category -eq "auth_required") { return "Export cookies.txt from a logged-in browser and pass -YtDlpCookiesPath, or retry with -YtDlpCookiesFromBrowser using an unlocked browser profile." }
  if ($Category -eq "video_unavailable") { return "Use another reference URL. This URL is unavailable from the current environment." }
  if ($Category -eq "missing_input") { return "The diagnostic script did not receive a URL or ytsearch input." }
  if ($Category -eq "rate_limited") { return "Wait, change network, or provide cookies." }
  if ($Category -eq "unsupported_url") { return "Use a supported YouTube URL, ytsearch query, or local reference video." }
  if ($Category -eq "network_error") { return "Retry after checking network access, or provide a local reference video." }
  return "Inspect the yt-dlp output and retry with cookies or a local reference video."
}

function Invoke-YtDlpProbe {
  param(
    [string]$YtDlp,
    [string]$TargetInput,
    [string]$Kind,
    [string]$CookiesFromBrowser,
    [string]$CookiesPath
  )
  $args = @("--simulate", "--no-playlist")
  if ($CookiesPath) {
    $args += @("--cookies", $CookiesPath)
  } elseif ($CookiesFromBrowser) {
    $args += @("--cookies-from-browser", $CookiesFromBrowser)
  }
  $args += $TargetInput

  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $output = @(& $YtDlp @args 2>&1)
    $exitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  $text = ($output | ForEach-Object { "$_" }) -join "`n"
  if ($exitCode -eq 0) {
    return [pscustomobject]@{
      kind = $Kind
      input = $TargetInput
      status = "passed"
      exit_code = $exitCode
      category = ""
      hint = ""
      output = $text
    }
  }
  $category = Get-YtDlpFailureCategory $text
  return [pscustomobject]@{
    kind = $Kind
    input = $TargetInput
    status = "failed"
    exit_code = $exitCode
    category = $category
    hint = Get-YtDlpFailureHint $category
    output = $text
  }
}

Set-Location -LiteralPath $Workspace
$ytDlp = Get-ToolPath "yt-dlp"
if (!$ytDlp) { throw "yt-dlp not found. Expected PATH, $env:USERPROFILE\.local\bin\yt-dlp.exe, or workspace tools\yt-dlp.exe." }

$versionOutput = @(& $ytDlp --version 2>&1)
$version = ($versionOutput | Select-Object -First 1)

$projectRoot = Join-Path $Workspace "projects\$ProjectId"
$logDir = Join-Path $projectRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$checks = @()
if ($ReferenceUrl) {
  $checks += Invoke-YtDlpProbe -YtDlp $ytDlp -TargetInput $ReferenceUrl -Kind "url" -CookiesFromBrowser $YtDlpCookiesFromBrowser -CookiesPath $YtDlpCookiesPath
}
if ($ReferenceSearchQuery) {
  $searchInput = "ytsearch{0}:{1}" -f $ReferenceSearchLimit, $ReferenceSearchQuery
  $checks += Invoke-YtDlpProbe -YtDlp $ytDlp -TargetInput $searchInput -Kind "ytsearch" -CookiesFromBrowser $YtDlpCookiesFromBrowser -CookiesPath $YtDlpCookiesPath
}

$failed = @($checks | Where-Object { $_.status -ne "passed" })
$authRequired = @($checks | Where-Object { $_.category -eq "auth_required" })
$cookieBlocked = @($checks | Where-Object { $_.category -in @("cookie_copy_failed", "browser_cookies_missing", "dpapi_decrypt_failed") })
$status = if ($failed.Count -eq 0) {
  "passed"
} elseif ($cookieBlocked.Count -gt 0) {
  "blocked-cookies"
} elseif ($authRequired.Count -gt 0) {
  "blocked-auth"
} else {
  "failed"
}

$reportPath = Join-Path $logDir "youtube-diagnostics.json"
$report = [pscustomobject]@{
  status = $status
  yt_dlp = $ytDlp
  yt_dlp_version = $version
  cookies_from_browser = $YtDlpCookiesFromBrowser
  cookies_path = $(if ($YtDlpCookiesPath) { $YtDlpCookiesPath } else { "" })
  checks = $checks
}
Write-Json $report $reportPath 8

[pscustomobject]@{
  status = $status
  project_id = $ProjectId
  yt_dlp = $ytDlp
  yt_dlp_version = $version
  report = $reportPath
  failed_count = $failed.Count
  categories = (@($failed | ForEach-Object { $_.category } | Where-Object { $_ } | Sort-Object -Unique) -join ",")
} | ConvertTo-Json -Depth 5

if ($RequireSuccess -and $status -ne "passed") {
  exit 1
}
