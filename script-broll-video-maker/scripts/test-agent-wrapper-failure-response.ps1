param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectId = "self-test-agent-wrapper-failure-response"
)

$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$wrapper = Join-Path $skillRoot "scripts\invoke-script-broll-video-agent.ps1"

$workspacePath = (Resolve-Path -LiteralPath $Workspace).Path
$sampleDir = Join-Path $workspacePath "samples"
New-Item -ItemType Directory -Force -Path $sampleDir | Out-Null

$requestPath = Join-Path $sampleDir "wrapper-failure-test-request.json"
$responsePath = Join-Path $workspacePath "projects\$ProjectId\render\agent-response.json"
$request = [pscustomobject]@{
  project_id = $ProjectId
  output_dir = "projects"
  tts = [pscustomobject]@{
    provider = "local-sapi"
  }
}
[System.IO.File]::WriteAllText($requestPath, ($request | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
  $output = powershell -NoProfile -ExecutionPolicy Bypass `
    -File $wrapper `
    -RequestPath $requestPath `
    -Workspace $workspacePath `
    -ResponsePath $responsePath 2>&1
  $exitCode = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
}

if ($exitCode -eq 0) { throw "Wrapper unexpectedly succeeded for an invalid request." }
if (!(Test-Path -LiteralPath $responsePath)) { throw "Failure response missing: $responsePath. Output: $($output -join ' ')" }

$response = Get-Content -Raw -Encoding UTF8 -LiteralPath $responsePath | ConvertFrom-Json
if ($response.status -ne "failed") { throw "Expected failed status, got $($response.status)." }
if ($response.phase -ne "request-validation") { throw "Expected request-validation phase, got $($response.phase)." }
if ($response.error -notmatch "document_path") { throw "Expected document_path error, got: $($response.error)" }
if ($response.project_id -ne $ProjectId) { throw "Expected project_id $ProjectId, got $($response.project_id)." }

[pscustomobject]@{
  status = "passed"
  project_id = $ProjectId
  wrapper_exit_code = $exitCode
  failure_phase = $response.phase
  response = $responsePath
} | ConvertTo-Json -Depth 6
