param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectId = "self-test-free-resource-skill-root",
  [string]$FreeResourceSkillRoot = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$wrapper = Join-Path $skillRoot "scripts\invoke-script-broll-video-agent.ps1"

if (!$FreeResourceSkillRoot -and $env:FREE_RESOURCE_SKILL_ROOT) {
  $FreeResourceSkillRoot = $env:FREE_RESOURCE_SKILL_ROOT
}
if (!$FreeResourceSkillRoot -or !(Test-Path -LiteralPath $FreeResourceSkillRoot -PathType Container)) {
  throw "FreeResourceSkillRoot is required and must point to the free-resource skill folder."
}

Set-Location -LiteralPath $Workspace
New-Item -ItemType Directory -Force -Path "samples" | Out-Null

$article = Join-Path $Workspace "samples\free-resource-skill-root-article.txt"
$articleText = @"
This integration test paragraph uses a simple local reference clip.

This key conclusion needs ocean waves cinematic stock footage from the configured free-resource skill.
"@
[System.IO.File]::WriteAllText($article, $articleText, [System.Text.UTF8Encoding]::new($false))

$reference = Join-Path $Workspace "samples\free-resource-skill-root-reference.mp4"
ffmpeg -y -hide_banner -v error `
  -f lavfi -i "color=c=black:s=1280x720:d=3" `
  -f lavfi -i "color=c=white:s=1280x720:d=3" `
  -filter_complex "[0:v][1:v]concat=n=2:v=1:a=0" `
  -pix_fmt yuv420p $reference | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Failed to create free-resource skill-root reference video." }

$requestPath = Join-Path $Workspace "samples\free-resource-skill-root-request.json"
$responsePath = Join-Path $Workspace "projects\$ProjectId\render\agent-response.json"
$request = [pscustomobject]@{
  document_path = $article
  project_id = $ProjectId
  output_dir = "projects"
  aspect_ratio = "16:9"
  tts = [pscustomobject]@{
    provider = "local-sapi"
    voice = ""
  }
  reference_videos = @(
    [pscustomobject]@{
      platform = "local"
      path = $reference
    }
  )
  free_resource = [pscustomobject]@{
    enabled = $true
    skill_root = $FreeResourceSkillRoot
    required_for_key_segments = $true
  }
  key_segment_rules = [pscustomobject]@{
    keywords = @("key", "ocean", "stock footage")
    manual_ids = @()
  }
  scene = [pscustomobject]@{
    threshold = 0.2
    min_duration_seconds = 1
    max_duration_seconds = 10
  }
  render = [pscustomobject]@{
    burn_subtitles = $false
  }
}
[System.IO.File]::WriteAllText($requestPath, ($request | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))

$output = powershell -NoProfile -ExecutionPolicy Bypass -File $wrapper `
  -RequestPath $requestPath `
  -Workspace $Workspace `
  -ResponsePath $responsePath
if ($LASTEXITCODE -ne 0) { throw "Wrapper failed with exit code $LASTEXITCODE. Output: $output" }

$response = Get-Content -LiteralPath $responsePath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($response.status -ne "completed") { throw "Wrapper response status was $($response.status)." }
if ($response.verification.status -ne "passed") { throw "Wrapper verification did not pass." }

$projectRoot = Join-Path $Workspace "projects\$ProjectId"
$assetPlanPath = Join-Path $projectRoot "timeline\asset_plan.json"
$assetPlan = Get-Content -LiteralPath $assetPlanPath -Raw -Encoding UTF8 | ConvertFrom-Json
$sourceTypes = @($assetPlan.segments | ForEach-Object { $_.source_type })
if ($sourceTypes -notcontains "free-resource") { throw "Wrapper did not use a free-resource asset." }

$manifests = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot "assets\free-resource") -Filter "free-resource-api-manifest.json" -Recurse)
if ($manifests.Count -eq 0) { throw "free-resource API manifest was not created." }
$manifest = Get-Content -LiteralPath $manifests[0].FullName -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.status -ne "completed") { throw "free-resource manifest status was $($manifest.status)." }

[pscustomobject]@{
  status = "passed"
  project_id = $ProjectId
  final_video = $response.final_video
  verification = $response.verification.status
  source_types = ($sourceTypes -join ",")
  free_resource_manifest = $manifests[0].FullName
  download_runner = $manifest.selected.download_runner
  response = $responsePath
} | ConvertTo-Json -Depth 6
