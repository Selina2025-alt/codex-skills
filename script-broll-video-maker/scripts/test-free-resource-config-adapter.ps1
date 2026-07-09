param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectId = "self-test-free-resource-config",
  [string]$FreeResourceSkillRoot = "",
  [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$adapter = Join-Path $skillRoot "scripts\free-resource-api-adapter.ps1"

Set-Location -LiteralPath $Workspace

if (!$FreeResourceSkillRoot -and $env:FREE_RESOURCE_SKILL_ROOT) {
  $FreeResourceSkillRoot = $env:FREE_RESOURCE_SKILL_ROOT
}
if (!$ConfigPath -and $env:FREE_RESOURCE_CONFIG_PATH) {
  $ConfigPath = $env:FREE_RESOURCE_CONFIG_PATH
}
if (!$ConfigPath -and $FreeResourceSkillRoot) {
  $ConfigPath = Join-Path $FreeResourceSkillRoot "config.json"
}
if (!$ConfigPath -or !(Test-Path -LiteralPath $ConfigPath)) {
  throw "ConfigPath is required and must point to free-resource config.json."
}

$outputDir = Join-Path $Workspace "projects\$ProjectId\assets\free-resource\seg_001"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$requestPath = Join-Path $outputDir "free-resource-request.json"
$request = [pscustomobject]@{
  segment_id = "seg_001"
  text = "This dry-run request validates loading API keys from a free-resource config file."
  query = "ocean waves cinematic"
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

$args = @(
  "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $adapter,
  "-RequestPath", $requestPath,
  "-OutputDir", $outputDir,
  "-ConfigPath", $ConfigPath,
  "-DryRun"
)
if ($FreeResourceSkillRoot) { $args += @("-FreeResourceSkillRoot", $FreeResourceSkillRoot) }

$json = powershell @args
if ($LASTEXITCODE -ne 0) { throw "Adapter config dry-run failed with exit code $LASTEXITCODE." }

$manifestPath = Join-Path $outputDir "free-resource-api-manifest.json"
if (!(Test-Path -LiteralPath $manifestPath)) { throw "Adapter manifest missing: $manifestPath" }

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.status -ne "dry-run") { throw "Unexpected dry-run status: $($manifest.status)" }
if (!$manifest.has_pexels_key -and !$manifest.has_pixabay_key) { throw "Adapter did not load Pexels or Pixabay keys from config." }

[pscustomobject]@{
  status = "passed"
  project_id = $ProjectId
  manifest = $manifestPath
  has_pexels_key = $manifest.has_pexels_key
  has_pixabay_key = $manifest.has_pixabay_key
  candidate_count = $manifest.candidate_count
  errors = @($manifest.errors).Count
} | ConvertTo-Json -Depth 5
