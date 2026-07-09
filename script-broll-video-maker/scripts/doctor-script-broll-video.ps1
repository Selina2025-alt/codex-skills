param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectId = "script-broll-doctor",
  [string]$FreeResourceSkillRoot = "",
  [string]$FreeResourceConfigPath = "",
  [string]$CookiesPath = "",
  [switch]$RunNetworkProbes,
  [switch]$RunWrapperSmoke
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

function Invoke-Version {
  param(
    [string]$Path,
    [string[]]$CommandArgs = @("--version")
  )
  if (!$Path -or !(Test-Path -LiteralPath $Path)) { return "" }
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $output = @(& $Path @CommandArgs 2>&1)
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  return (($output | Select-Object -First 1) -join "")
}

function Add-Check {
  param(
    [System.Collections.Generic.List[object]]$Checks,
    [string]$Name,
    [string]$Status,
    [string]$Severity,
    [string]$Message,
    [hashtable]$Data = @{}
  )
  $Checks.Add([pscustomobject]@{
    name = $Name
    status = $Status
    severity = $Severity
    message = $Message
    data = [pscustomobject]$Data
  }) | Out-Null
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

function Test-NetscapeCookieLine {
  param([string]$Line)
  if (!$Line -or $Line.StartsWith("#")) { return $false }
  $parts = $Line -split "`t"
  return ($parts.Count -ge 7)
}

function Inspect-CookiesFile {
  param([string]$Path)
  if (!$Path) {
    return [pscustomobject]@{ status = "missing"; path = ""; cookie_count = 0; youtube_cookie_count = 0; google_cookie_count = 0 }
  }
  if (!(Test-Path -LiteralPath $Path -PathType Leaf)) {
    return [pscustomobject]@{ status = "missing"; path = $Path; cookie_count = 0; youtube_cookie_count = 0; google_cookie_count = 0 }
  }
  $resolved = (Resolve-Path -LiteralPath $Path).Path
  $lines = [System.IO.File]::ReadAllLines($resolved)
  $cookieLines = @($lines | Where-Object { Test-NetscapeCookieLine $_ })
  $youtube = 0
  $google = 0
  foreach ($line in $cookieLines) {
    $domain = ($line -split "`t")[0]
    if ($domain -match "youtube\.com|youtube-nocookie\.com") { $youtube += 1 }
    elseif ($domain -match "google\.com") { $google += 1 }
  }
  $status = if ($cookieLines.Count -eq 0) { "invalid" } elseif (($youtube + $google) -eq 0) { "warning-no-youtube-domain" } else { "valid" }
  return [pscustomobject]@{
    status = $status
    path = $resolved
    cookie_count = $cookieLines.Count
    youtube_cookie_count = $youtube
    google_cookie_count = $google
  }
}

function Read-FreeResourceConfig {
  param([string]$Path)
  if (!$Path -or !(Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
  return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$workspacePath = (Resolve-Path -LiteralPath $Workspace).Path
Set-Location -LiteralPath $workspacePath

$projectRoot = Join-Path $workspacePath "projects\$ProjectId"
$logDir = Join-Path $projectRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$checks = [System.Collections.Generic.List[object]]::new()

$envPaths = @(
  (Join-Path $workspacePath ".env"),
  (Join-Path $env:USERPROFILE ".codex\.env"),
  (Join-Path $env:USERPROFILE ".agents\.env")
)

if (!$FreeResourceSkillRoot) {
  $FreeResourceSkillRoot = Get-DotEnvValue -Paths $envPaths -Key "FREE_RESOURCE_SKILL_ROOT"
}
if (!$FreeResourceConfigPath) {
  $FreeResourceConfigPath = Get-DotEnvValue -Paths $envPaths -Key "FREE_RESOURCE_CONFIG_PATH"
}
if (!$FreeResourceConfigPath -and $FreeResourceSkillRoot) {
  $FreeResourceConfigPath = Join-Path $FreeResourceSkillRoot "config.json"
}
if (!$CookiesPath) {
  $CookiesPath = Get-DotEnvValue -Paths $envPaths -Key "YTDLP_COOKIES_PATH"
}

Add-Check -Checks $checks -Name "workspace" -Status "passed" -Severity "required" -Message "Workspace exists." -Data @{ path = $workspacePath }
Add-Check -Checks $checks -Name "skill_root" -Status "passed" -Severity "required" -Message "Skill root resolved." -Data @{ path = $skillRoot }

$ffmpeg = Get-ToolPath "ffmpeg"
if ($ffmpeg) {
  Add-Check -Checks $checks -Name "ffmpeg" -Status "passed" -Severity "required" -Message "ffmpeg is available." -Data @{ path = $ffmpeg; version = (Invoke-Version -Path $ffmpeg -CommandArgs @("-version")) }
} else {
  Add-Check -Checks $checks -Name "ffmpeg" -Status "failed" -Severity "required" -Message "ffmpeg is missing." -Data @{}
}

$ffprobe = Get-ToolPath "ffprobe"
if ($ffprobe) {
  Add-Check -Checks $checks -Name "ffprobe" -Status "passed" -Severity "required" -Message "ffprobe is available." -Data @{ path = $ffprobe; version = (Invoke-Version -Path $ffprobe -CommandArgs @("-version")) }
} else {
  Add-Check -Checks $checks -Name "ffprobe" -Status "failed" -Severity "required" -Message "ffprobe is missing." -Data @{}
}

try {
  Add-Type -AssemblyName System.Speech
  $synth = [System.Speech.Synthesis.SpeechSynthesizer]::new()
  try {
    $voices = @($synth.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo.Name })
  } finally {
    $synth.Dispose()
  }
  Add-Check -Checks $checks -Name "local_sapi_tts" -Status "passed" -Severity "required" -Message "Windows SAPI TTS is available." -Data @{ voice_count = $voices.Count; sample_voices = @($voices | Select-Object -First 5) }
} catch {
  Add-Check -Checks $checks -Name "local_sapi_tts" -Status "failed" -Severity "required" -Message "Windows SAPI TTS is unavailable: $($_.Exception.Message)" -Data @{}
}

$ytDlp = Get-ToolPath "yt-dlp"
if ($ytDlp) {
  Add-Check -Checks $checks -Name "yt_dlp" -Status "passed" -Severity "recommended" -Message "yt-dlp is available." -Data @{ path = $ytDlp; version = (Invoke-Version -Path $ytDlp) }
} else {
  Add-Check -Checks $checks -Name "yt_dlp" -Status "warning" -Severity "recommended" -Message "yt-dlp is missing; YouTube references will not download." -Data @{}
}

$bun = Get-ToolPath "bun"
if ($bun) {
  Add-Check -Checks $checks -Name "bun" -Status "passed" -Severity "recommended" -Message "Bun is available for free-resource CLI." -Data @{ path = $bun; version = (Invoke-Version -Path $bun -CommandArgs @("--version")) }
} else {
  Add-Check -Checks $checks -Name "bun" -Status "warning" -Severity "recommended" -Message "Bun is missing; free-resource CLI fallback may not run." -Data @{}
}

if ($FreeResourceSkillRoot -and (Test-Path -LiteralPath $FreeResourceSkillRoot -PathType Container)) {
  $pexelsScript = Join-Path $FreeResourceSkillRoot "scripts\pexels.ts"
  $pixabayScript = Join-Path $FreeResourceSkillRoot "scripts\pixabay.ts"
  Add-Check -Checks $checks -Name "free_resource_skill_root" -Status "passed" -Severity "recommended" -Message "free-resource skill root exists." -Data @{
    path = (Resolve-Path -LiteralPath $FreeResourceSkillRoot).Path
    has_pexels_script = (Test-Path -LiteralPath $pexelsScript)
    has_pixabay_script = (Test-Path -LiteralPath $pixabayScript)
  }
} else {
  Add-Check -Checks $checks -Name "free_resource_skill_root" -Status "warning" -Severity "recommended" -Message "free-resource skill root is not configured or missing." -Data @{ path = $FreeResourceSkillRoot }
}

$freeConfig = Read-FreeResourceConfig -Path $FreeResourceConfigPath
if ($freeConfig) {
  Add-Check -Checks $checks -Name "free_resource_config" -Status "passed" -Severity "recommended" -Message "free-resource config loaded." -Data @{
    path = (Resolve-Path -LiteralPath $FreeResourceConfigPath).Path
    has_pexels_key = [bool]$freeConfig.pexels.api_key
    has_pixabay_key = [bool]$freeConfig.pixabay.api_key
    has_freesound_token = [bool]$freeConfig.freesound.api_token
    has_jamendo_client_id = [bool]$freeConfig.jamendo.client_id
  }
} else {
  Add-Check -Checks $checks -Name "free_resource_config" -Status "warning" -Severity "recommended" -Message "free-resource config is not configured or missing." -Data @{ path = $FreeResourceConfigPath }
}

$cookies = Inspect-CookiesFile -Path $CookiesPath
if ($cookies.status -eq "valid") {
  Add-Check -Checks $checks -Name "youtube_cookies" -Status "passed" -Severity "recommended" -Message "cookies.txt appears usable." -Data @{
    path = $cookies.path
    cookie_count = $cookies.cookie_count
    youtube_cookie_count = $cookies.youtube_cookie_count
    google_cookie_count = $cookies.google_cookie_count
  }
} elseif ($cookies.status -eq "missing") {
  Add-Check -Checks $checks -Name "youtube_cookies" -Status "warning" -Severity "recommended" -Message "cookies.txt is not configured; YouTube may require login." -Data @{ path = $cookies.path }
} else {
  Add-Check -Checks $checks -Name "youtube_cookies" -Status "warning" -Severity "recommended" -Message "cookies.txt needs attention: $($cookies.status)." -Data @{
    path = $cookies.path
    cookie_count = $cookies.cookie_count
    youtube_cookie_count = $cookies.youtube_cookie_count
    google_cookie_count = $cookies.google_cookie_count
  }
}

if ($RunNetworkProbes) {
  $youtubeDiagnostics = Join-Path $skillRoot "scripts\test-youtube-reference-diagnostics.ps1"
  $ytArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $youtubeDiagnostics, "-Workspace", $workspacePath, "-ProjectId", "$ProjectId-youtube")
  if ($cookies.status -eq "valid") { $ytArgs += @("-YtDlpCookiesPath", $cookies.path) }
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $ytOutput = @(powershell @ytArgs 2>&1)
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  $ytReportPath = Join-Path $workspacePath "projects\$ProjectId-youtube\logs\youtube-diagnostics.json"
  $ytReport = if (Test-Path -LiteralPath $ytReportPath) {
    Get-Content -LiteralPath $ytReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
  } else {
    [pscustomobject]@{ status = "missing"; output = ($ytOutput -join "`n") }
  }
  $ytStatus = if ($ytReport.status -eq "passed") { "passed" } else { "warning" }
  Add-Check -Checks $checks -Name "youtube_network_probe" -Status $ytStatus -Severity "optional" -Message "YouTube network probe completed with status $($ytReport.status)." -Data @{ report = $ytReportPath; status = $ytReport.status }

  if ($FreeResourceSkillRoot -and $FreeResourceConfigPath) {
    $freeTest = Join-Path $skillRoot "scripts\test-free-resource-config-adapter.ps1"
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
      $freeOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File $freeTest -Workspace $workspacePath -ProjectId "$ProjectId-free-resource" -FreeResourceSkillRoot $FreeResourceSkillRoot -ConfigPath $FreeResourceConfigPath 2>&1)
      $freeExit = $LASTEXITCODE
    } finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
    $freeStatus = if ($freeExit -eq 0) { "passed" } else { "warning" }
    Add-Check -Checks $checks -Name "free_resource_network_probe" -Status $freeStatus -Severity "optional" -Message "free-resource network probe completed." -Data @{ exit_code = $freeExit; output = ($freeOutput -join "`n") }
  }
}

if ($RunWrapperSmoke) {
  $wrapperTest = Join-Path $skillRoot "scripts\test-agent-wrapper.ps1"
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $wrapperOutput = @(powershell -NoProfile -ExecutionPolicy Bypass -File $wrapperTest -Workspace $workspacePath -ProjectId "$ProjectId-wrapper-smoke" 2>&1)
    $wrapperExit = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  $status = if ($wrapperExit -eq 0) { "passed" } else { "failed" }
  Add-Check -Checks $checks -Name "wrapper_smoke" -Status $status -Severity "required" -Message "Wrapper smoke test completed." -Data @{ exit_code = $wrapperExit; output = ($wrapperOutput -join "`n") }
}

$failedRequired = @($checks | Where-Object { $_.severity -eq "required" -and $_.status -eq "failed" })
$warnings = @($checks | Where-Object { $_.status -eq "warning" })
$overall = if ($failedRequired.Count -gt 0) {
  "failed"
} elseif ($warnings.Count -gt 0) {
  "ready-with-warnings"
} else {
  "ready"
}

$reportPath = Join-Path $logDir "script-broll-doctor.json"
$report = [pscustomobject]@{
  status = $overall
  workspace = $workspacePath
  skill_root = $skillRoot
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  checks = $checks
}
Write-Json $report $reportPath 12

[pscustomobject]@{
  status = $overall
  project_id = $ProjectId
  report = $reportPath
  failed_required = $failedRequired.Count
  warnings = $warnings.Count
  checks = $checks.Count
} | ConvertTo-Json -Depth 5
