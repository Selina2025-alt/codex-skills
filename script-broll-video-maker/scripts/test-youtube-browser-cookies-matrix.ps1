param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectId = "self-test-youtube-browser-cookies",
  [string[]]$Browsers = @("edge", "chrome", "firefox"),
  [string]$ReferenceSearchQuery = "technology documentary b-roll",
  [int]$ReferenceSearchLimit = 1
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

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$diagnostics = Join-Path $skillRoot "scripts\test-youtube-reference-diagnostics.ps1"
if (!(Test-Path -LiteralPath $diagnostics)) { throw "Missing diagnostics script: $diagnostics" }

Set-Location -LiteralPath $Workspace
$projectRoot = Join-Path $Workspace "projects\$ProjectId"
$logDir = Join-Path $projectRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$results = @()
foreach ($browser in $Browsers) {
  $childProjectId = "$ProjectId-$browser"
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $output = @(powershell -NoProfile -ExecutionPolicy Bypass -File $diagnostics `
      -Workspace $Workspace `
      -ProjectId $childProjectId `
      -ReferenceSearchQuery $ReferenceSearchQuery `
      -ReferenceSearchLimit $ReferenceSearchLimit `
      -YtDlpCookiesFromBrowser $browser 2>&1)
    $exitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }

  $reportPath = Join-Path $Workspace "projects\$childProjectId\logs\youtube-diagnostics.json"
  $report = if (Test-Path -LiteralPath $reportPath) {
    Get-Content -LiteralPath $reportPath -Raw -Encoding UTF8 | ConvertFrom-Json
  } else {
    [pscustomobject]@{
      status = "failed"
      checks = @(
        [pscustomobject]@{
          status = "failed"
          category = "missing_report"
          hint = "The browser diagnostics child report was not created."
          output = ($output -join "`n")
        }
      )
    }
  }
  $failedCategories = @($report.checks | Where-Object { $_.status -ne "passed" } | ForEach-Object { $_.category } | Where-Object { $_ } | Sort-Object -Unique)
  $hints = @($report.checks | Where-Object { $_.status -ne "passed" } | ForEach-Object { $_.hint } | Where-Object { $_ } | Sort-Object -Unique)
  $results += [pscustomobject]@{
    browser = $browser
    status = $report.status
    exit_code = $exitCode
    categories = $failedCategories
    hints = $hints
    report = $reportPath
  }
}

$usable = @($results | Where-Object { $_.status -eq "passed" })
$cookieBlocked = @($results | Where-Object { $_.categories -contains "cookie_copy_failed" -or $_.categories -contains "browser_cookies_missing" -or $_.categories -contains "dpapi_decrypt_failed" })
$authBlocked = @($results | Where-Object { $_.categories -contains "auth_required" })
$status = if ($usable.Count -gt 0) {
  "passed"
} elseif ($cookieBlocked.Count -gt 0) {
  "blocked-cookies"
} elseif ($authBlocked.Count -gt 0) {
  "blocked-auth"
} else {
  "failed"
}

$summaryPath = Join-Path $logDir "youtube-browser-cookies-matrix.json"
$summary = [pscustomobject]@{
  status = $status
  browsers = $Browsers
  reference_search_query = $ReferenceSearchQuery
  reference_search_limit = $ReferenceSearchLimit
  results = $results
}
Write-Json $summary $summaryPath 10

[pscustomobject]@{
  status = $status
  project_id = $ProjectId
  tested_browsers = ($Browsers -join ",")
  usable_browsers = (@($usable | ForEach-Object { $_.browser }) -join ",")
  categories = (@($results | ForEach-Object { $_.categories } | Where-Object { $_ } | Sort-Object -Unique) -join ",")
  report = $summaryPath
} | ConvertTo-Json -Depth 5
