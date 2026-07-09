param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectId = "skill-v020-minimal-job"
)

$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$entry = Join-Path $skillRoot "run.ps1"
$mockFreeResource = Join-Path $skillRoot "scripts\mock-free-resource.ps1"

$workspacePath = (Resolve-Path -LiteralPath $Workspace).Path
$sampleDir = Join-Path $workspacePath "samples"
New-Item -ItemType Directory -Force -Path $sampleDir | Out-Null

$reference = Join-Path $sampleDir "skill-v020-reference.mp4"
ffmpeg -y -hide_banner -v error `
  -f lavfi -i "testsrc2=s=1280x720:d=4" `
  -f lavfi -i "smptebars=s=1280x720:d=4" `
  -filter_complex "[0:v][1:v]concat=n=2:v=1:a=0" `
  -pix_fmt yuv420p $reference | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Failed to create local reference video." }

$requestPath = Join-Path $sampleDir "skill-v020-minimal-job.json"
$responsePath = Join-Path $workspacePath "projects\$ProjectId\render\agent-response.json"
$request = [pscustomobject]@{
  project_id = $ProjectId
  script_text = "This is a minimal script for the skill test. The narration must match this text exactly.`n`nThis key segment should trigger authorized B-roll through the mock free-resource adapter."
  target_platforms = @("bilibili")
  output_aspect_ratios = @("16:9")
  voice_config = [pscustomobject]@{
    provider = "local-sapi"
    voice = ""
  }
  source_policy = [pscustomobject]@{
    reference_video_paths = @($reference)
    free_resource_command = $mockFreeResource
    required_for_key_segments = $false
    key_segment_keywords = @("key", "authorized")
  }
  output_dir = "projects"
  max_segment_chars = 120
  scene = [pscustomobject]@{
    threshold = 0.2
    min_duration_seconds = 1
    max_duration_seconds = 10
  }
  render = [pscustomobject]@{
    burn_subtitles = $false
  }
}
[System.IO.File]::WriteAllText($requestPath, ($request | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
  $output = powershell -NoProfile -ExecutionPolicy Bypass -File $entry `
    -RequestPath $requestPath `
    -Workspace $workspacePath `
    -ResponsePath $responsePath 2>&1
  $exitCode = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
}

if ($exitCode -ne 0) { throw "Minimal job failed with exit code $exitCode. Output: $($output -join ' ')" }
if (!(Test-Path -LiteralPath $responsePath)) { throw "Response missing: $responsePath" }

$response = Get-Content -LiteralPath $responsePath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($response.status -ne "completed") { throw "Expected completed status, got $($response.status)." }
foreach ($path in @($response.final_video_path, $response.srt_path, $response.audio_path, $response.timeline_path)) {
  if (!$path -or !(Test-Path -LiteralPath $path)) { throw "Expected output path missing: $path" }
}
if (@($response.used_assets).Count -eq 0) { throw "Expected used_assets in response." }

[pscustomobject]@{
  status = "passed"
  project_id = $ProjectId
  response = $responsePath
  final_video_path = $response.final_video_path
  used_asset_count = @($response.used_assets).Count
} | ConvertTo-Json -Depth 8
