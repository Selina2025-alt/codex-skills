param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectId = "self-test-free-resource-api"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$adapter = Join-Path $skillRoot "scripts\free-resource-api-adapter.ps1"

Set-Location -LiteralPath $Workspace
$outputDir = Join-Path $Workspace "projects\$ProjectId\assets\free-resource\seg_001"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$requestPath = Join-Path $outputDir "free-resource-request.json"
$request = [pscustomobject]@{
  segment_id = "seg_001"
  text = "This dry-run request validates the Pexels and Pixabay adapter contract."
  query = "city night technology office"
  media_type = "video"
  aspect_ratio = "16:9"
  output_dir = $outputDir
  source_priority = @("pexels", "pixabay")
}
[System.IO.File]::WriteAllText(
  $requestPath,
  ($request | ConvertTo-Json -Depth 5),
  [System.Text.UTF8Encoding]::new($false)
)

$json = powershell -NoProfile -ExecutionPolicy Bypass -File $adapter `
  -RequestPath $requestPath `
  -OutputDir $outputDir `
  -DryRun
if ($LASTEXITCODE -ne 0) { throw "Adapter dry-run failed with exit code $LASTEXITCODE." }

$manifestPath = Join-Path $outputDir "free-resource-api-manifest.json"
if (!(Test-Path -LiteralPath $manifestPath)) { throw "Adapter manifest missing: $manifestPath" }

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.status -ne "dry-run") { throw "Unexpected dry-run status: $($manifest.status)" }
if ($manifest.segment_id -ne "seg_001") { throw "Unexpected segment id: $($manifest.segment_id)" }
if (!$manifest.query) { throw "Dry-run manifest missing query." }

[pscustomobject]@{
  status = "passed"
  project_id = $ProjectId
  manifest = $manifestPath
  has_pexels_key = $manifest.has_pexels_key
  has_pixabay_key = $manifest.has_pixabay_key
  candidate_count = $manifest.candidate_count
} | ConvertTo-Json -Depth 5
