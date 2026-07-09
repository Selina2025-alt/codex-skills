param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectId = "self-test-youtube-cookies-config"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$configure = Join-Path $skillRoot "scripts\configure-youtube-cookies.ps1"

Set-Location -LiteralPath $Workspace
$projectRoot = Join-Path $Workspace "projects\$ProjectId"
$fixtureDir = Join-Path $projectRoot "fixtures"
New-Item -ItemType Directory -Force -Path $fixtureDir | Out-Null

$cookiesPath = Join-Path $fixtureDir "youtube-cookies.txt"
$expiry = [DateTimeOffset]::UtcNow.AddDays(30).ToUnixTimeSeconds()
$cookieText = @"
# Netscape HTTP Cookie File
.youtube.com	TRUE	/	TRUE	$expiry	LOGIN_INFO	fake-login-info
.google.com	TRUE	/	TRUE	$expiry	SID	fake-sid
"@
[System.IO.File]::WriteAllText($cookiesPath, $cookieText, [System.Text.UTF8Encoding]::new($false))

$envPath = Join-Path $projectRoot ".env"
$output = powershell -NoProfile -ExecutionPolicy Bypass -File $configure `
  -Workspace $Workspace `
  -ProjectId $ProjectId `
  -CookiesPath $cookiesPath `
  -EnvPath $envPath `
  -SkipYtDlpProbe
if ($LASTEXITCODE -ne 0) { throw "configure-youtube-cookies failed with exit code $LASTEXITCODE. Output: $output" }

$response = $output | ConvertFrom-Json
if ($response.status -ne "configured") { throw "Unexpected configure status: $($response.status)" }
if ($response.cookies_status -ne "valid") { throw "Unexpected cookies status: $($response.cookies_status)" }
if (!(Test-Path -LiteralPath $envPath)) { throw "Expected .env file missing: $envPath" }
$envText = Get-Content -LiteralPath $envPath -Raw -Encoding UTF8
if ($envText -notmatch "YTDLP_COOKIES_PATH") { throw ".env did not include YTDLP_COOKIES_PATH." }
if ($envText -notmatch "YTDLP_COOKIES_FROM_BROWSER") { throw ".env did not neutralize YTDLP_COOKIES_FROM_BROWSER." }

[pscustomobject]@{
  status = "passed"
  project_id = $ProjectId
  env_path = $envPath
  cookies_path = $cookiesPath
  report = $response.report
} | ConvertTo-Json -Depth 5
