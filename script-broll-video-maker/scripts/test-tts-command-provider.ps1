param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectId = "self-test-tts-command-provider"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$wrapper = Join-Path $skillRoot "scripts\invoke-script-broll-video-agent.ps1"
$mockFreeResource = Join-Path $skillRoot "scripts\mock-free-resource.ps1"
$mockTtsProvider = Join-Path $skillRoot "scripts\mock-tts-provider.ps1"

Set-Location -LiteralPath $Workspace
New-Item -ItemType Directory -Force -Path "samples" | Out-Null

$article = Join-Path $Workspace "samples\tts-command-test-article.txt"
$articleText = @"
This command TTS test paragraph validates the replaceable provider interface.

This key conclusion paragraph should still use the free-resource visual path.
"@
[System.IO.File]::WriteAllText($article, $articleText, [System.Text.UTF8Encoding]::new($false))

$reference = Join-Path $Workspace "samples\tts-command-test-reference.mp4"
ffmpeg -y -hide_banner -v error `
  -f lavfi -i "color=c=navy:s=1280x720:d=3" `
  -f lavfi -i "color=c=gray:s=1280x720:d=3" `
  -f lavfi -i "color=c=olive:s=1280x720:d=3" `
  -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0" `
  -pix_fmt yuv420p $reference | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Failed to create command-TTS reference video." }

$requestPath = Join-Path $Workspace "samples\tts-command-test-request.json"
$responsePath = Join-Path $Workspace "projects\$ProjectId\render\agent-response.json"
$request = [pscustomobject]@{
  document_path = $article
  project_id = $ProjectId
  output_dir = "projects"
  aspect_ratio = "16:9"
  tts = [pscustomobject]@{
    provider = "command"
    command = $mockTtsProvider
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
if ($LASTEXITCODE -ne 0) { throw "Wrapper failed with exit code $LASTEXITCODE. Output: $output" }

if (!(Test-Path -LiteralPath $responsePath)) { throw "Wrapper response missing: $responsePath" }
$response = Get-Content -LiteralPath $responsePath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($response.status -ne "completed") { throw "Wrapper response status was $($response.status)." }
if ($response.verification.status -ne "passed") { throw "Wrapper verification did not pass." }

$projectRoot = Join-Path $Workspace "projects\$ProjectId"
$audioManifestPath = Join-Path $projectRoot "audio\audio_manifest.json"
$audioManifest = Get-Content -LiteralPath $audioManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($audioManifest.provider -ne "command") { throw "Audio manifest provider was $($audioManifest.provider)." }

$ttsRequest = Join-Path $projectRoot "audio\tts_requests\seg_001.json"
if (!(Test-Path -LiteralPath $ttsRequest)) { throw "Command TTS request missing: $ttsRequest" }

[pscustomobject]@{
  status = "passed"
  project_id = $ProjectId
  final_video = $response.final_video
  verification = $response.verification.status
  tts_provider = $audioManifest.provider
  tts_request = $ttsRequest
  response = $responsePath
} | ConvertTo-Json -Depth 6
