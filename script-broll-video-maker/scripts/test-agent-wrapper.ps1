param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectId = "self-test-agent-wrapper"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$wrapper = Join-Path $skillRoot "scripts\invoke-script-broll-video-agent.ps1"
$mockFreeResource = Join-Path $skillRoot "scripts\mock-free-resource.ps1"

Set-Location -LiteralPath $Workspace
New-Item -ItemType Directory -Force -Path "samples" | Out-Null

$article = Join-Path $Workspace "samples\wrapper-test-article.txt"
$articleText = @"
This wrapper test paragraph checks the JSON sub-agent entrypoint.

This key conclusion paragraph should route through the free-resource adapter.
"@
[System.IO.File]::WriteAllText($article, $articleText, [System.Text.UTF8Encoding]::new($false))

$reference = Join-Path $Workspace "samples\wrapper-test-reference.mp4"
ffmpeg -y -hide_banner -v error `
  -f lavfi -i "color=c=orange:s=1280x720:d=3" `
  -f lavfi -i "color=c=purple:s=1280x720:d=3" `
  -f lavfi -i "color=c=teal:s=1280x720:d=3" `
  -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0" `
  -pix_fmt yuv420p $reference | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Failed to create wrapper-test reference video." }

$requestPath = Join-Path $Workspace "samples\wrapper-test-request.json"
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
    command = $mockFreeResource
    required_for_key_segments = $true
  }
  key_segment_rules = [pscustomobject]@{
    keywords = @("key", "conclusion")
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
if ($LASTEXITCODE -ne 0) { throw "Wrapper failed with exit code $LASTEXITCODE." }

if (!(Test-Path -LiteralPath $responsePath)) { throw "Wrapper response missing: $responsePath" }
$response = Get-Content -LiteralPath $responsePath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($response.status -ne "completed") { throw "Wrapper response status was $($response.status)." }
if (!(Test-Path -LiteralPath $response.final_video)) { throw "Wrapper final video missing: $($response.final_video)" }
if ($response.verification.status -ne "passed") { throw "Wrapper verification did not pass." }

[pscustomobject]@{
  status = "passed"
  project_id = $ProjectId
  final_video = $response.final_video
  verification = $response.verification.status
  response = $responsePath
} | ConvertTo-Json -Depth 6
