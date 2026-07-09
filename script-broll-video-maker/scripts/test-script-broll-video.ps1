param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectId = "self-test-script-broll-video"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$runner = Join-Path $skillRoot "scripts\run-script-broll-video.ps1"
$mockFreeResource = Join-Path $skillRoot "scripts\mock-free-resource.ps1"

Set-Location -LiteralPath $Workspace
New-Item -ItemType Directory -Force -Path "samples" | Out-Null

$article = Join-Path $Workspace "samples\self-test-article.txt"
$articleText = @"
This is a self test paragraph. The narration must match this text exactly.

This key conclusion paragraph should use the free-resource adapter because it includes the key keyword.
"@
[System.IO.File]::WriteAllText($article, $articleText, [System.Text.UTF8Encoding]::new($false))

$reference = Join-Path $Workspace "samples\self-test-reference.mp4"
ffmpeg -y -hide_banner `
  -v error `
  -f lavfi -i "color=c=red:s=1280x720:d=3" `
  -f lavfi -i "color=c=blue:s=1280x720:d=3" `
  -f lavfi -i "color=c=green:s=1280x720:d=3" `
  -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0" `
  -pix_fmt yuv420p $reference | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Failed to create self-test reference video." }

$selfTestLogDir = Join-Path $Workspace "projects\$ProjectId\logs"
New-Item -ItemType Directory -Force -Path $selfTestLogDir | Out-Null
$runnerLog = Join-Path $selfTestLogDir "self-test-runner.log"

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
  $runnerOutput = powershell -NoProfile -ExecutionPolicy Bypass -File $runner `
    -DocumentPath $article `
    -ProjectId $ProjectId `
    -OutputRoot "projects" `
    -KeySegmentKeywords "key,conclusion" `
    -ReferenceVideoPath $reference `
    -FreeResourceCommand $mockFreeResource `
    -SceneThreshold 0.2 `
    -SceneMinDuration 1 `
    -SceneMaxDuration 10 2>&1
  $runnerExitCode = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
}
$runnerOutput | Out-File -LiteralPath $runnerLog -Encoding UTF8
if ($runnerExitCode -ne 0) { throw "Runner failed with exit code $runnerExitCode." }

$resultPath = Join-Path $Workspace "projects\$ProjectId\render\result.json"
$resultObject = Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8 | ConvertFrom-Json

$final = $resultObject.final_video
if (!(Test-Path -LiteralPath $final)) { throw "Final video missing: $final" }

$streamsJson = ffprobe -v error -show_entries stream=index,codec_type,codec_name,width,height:format=duration -of json $final
$streams = $streamsJson | ConvertFrom-Json
$types = @($streams.streams | ForEach-Object { $_.codec_type })
foreach ($required in @("video", "audio", "subtitle")) {
  if ($types -notcontains $required) { throw "Final video missing $required stream." }
}

$assetPlanPath = Join-Path $Workspace "projects\$ProjectId\timeline\asset_plan.json"
$assetPlan = Get-Content -LiteralPath $assetPlanPath -Raw -Encoding UTF8 | ConvertFrom-Json
$sourceTypes = @($assetPlan.segments | ForEach-Object { $_.source_type })
if ($sourceTypes -notcontains "reference_video") { throw "Self-test did not use reference_video." }
if ($sourceTypes -notcontains "free-resource") { throw "Self-test did not use free-resource." }

[pscustomobject]@{
  status = "passed"
  project_id = $ProjectId
  final_video = $final
  streams = ($types -join ",")
  source_types = ($sourceTypes -join ",")
} | ConvertTo-Json -Depth 4
