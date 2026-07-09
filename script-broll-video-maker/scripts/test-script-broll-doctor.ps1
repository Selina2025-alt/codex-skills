param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectId = "self-test-script-broll-doctor",
  [string]$FreeResourceSkillRoot = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$doctor = Join-Path $skillRoot "scripts\doctor-script-broll-video.ps1"

$args = @(
  "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $doctor,
  "-Workspace", $Workspace,
  "-ProjectId", $ProjectId
)
if ($FreeResourceSkillRoot -and (Test-Path -LiteralPath $FreeResourceSkillRoot -PathType Container)) {
  $args += @("-FreeResourceSkillRoot", $FreeResourceSkillRoot)
}

$output = powershell @args
if ($LASTEXITCODE -ne 0) { throw "Doctor failed with exit code $LASTEXITCODE. Output: $output" }
$response = $output | ConvertFrom-Json
if ($response.status -notin @("ready", "ready-with-warnings")) { throw "Unexpected doctor status: $($response.status)" }
if (!(Test-Path -LiteralPath $response.report)) { throw "Doctor report missing: $($response.report)" }

$report = Get-Content -LiteralPath $response.report -Raw -Encoding UTF8 | ConvertFrom-Json
$requiredFailed = @($report.checks | Where-Object { $_.severity -eq "required" -and $_.status -eq "failed" })
if ($requiredFailed.Count -gt 0) { throw "Doctor reported failed required checks." }

[pscustomobject]@{
  status = "passed"
  project_id = $ProjectId
  doctor_status = $response.status
  warnings = $response.warnings
  report = $response.report
} | ConvertTo-Json -Depth 5
