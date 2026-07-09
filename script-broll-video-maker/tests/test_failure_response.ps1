param(
  [string]$Workspace = (Get-Location).Path,
  [string]$ProjectPrefix = "skill-v020-failure"
)

$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$entry = Join-Path $skillRoot "run.ps1"
$workspacePath = (Resolve-Path -LiteralPath $Workspace).Path
$sampleDir = Join-Path $workspacePath "samples"
New-Item -ItemType Directory -Force -Path $sampleDir | Out-Null

function Write-TestRequest {
  param([object]$Value, [string]$Name)
  $path = Join-Path $sampleDir "$Name.json"
  [System.IO.File]::WriteAllText($path, ($Value | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
  return $path
}

function Invoke-FailureCase {
  param(
    [string]$Name,
    [string]$RequestPath,
    [string]$ExpectedErrorPattern
  )
  $responsePath = Join-Path $workspacePath "projects\$ProjectPrefix-$Name\render\agent-response.json"
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $output = powershell -NoProfile -ExecutionPolicy Bypass -File $entry `
      -RequestPath $RequestPath `
      -Workspace $workspacePath `
      -ResponsePath $responsePath 2>&1
    $exitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }

  if ($exitCode -eq 0) { throw "Failure case $Name unexpectedly succeeded." }
  if (!(Test-Path -LiteralPath $responsePath)) { throw "Failure response missing for $Name. Output: $($output -join ' ')" }
  $response = Get-Content -LiteralPath $responsePath -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($response.status -ne "failed") { throw "Expected failed status for $Name, got $($response.status)." }
  if ($response.error -notmatch $ExpectedErrorPattern) { throw "Unexpected error for ${Name}: $($response.error)" }
  return [pscustomobject]@{
    name = $Name
    status = "passed"
    phase = $response.phase
    response = $responsePath
    error = $response.error
  }
}

$reference = Join-Path $sampleDir "skill-v020-failure-reference.mp4"
ffmpeg -y -hide_banner -v error -f lavfi -i "testsrc2=s=1280x720:d=3" -pix_fmt yuv420p $reference | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Failed to create local reference video." }

$missingDocumentRequest = Write-TestRequest -Name "$ProjectPrefix-missing-document" -Value ([pscustomobject]@{
  project_id = "$ProjectPrefix-missing-document"
  output_dir = "projects"
})

$badTtsRequest = Write-TestRequest -Name "$ProjectPrefix-bad-tts" -Value ([pscustomobject]@{
  project_id = "$ProjectPrefix-bad-tts"
  script_text = "This request should fail before rendering because command TTS has no command."
  output_dir = "projects"
  voice_config = [pscustomobject]@{
    provider = "command"
  }
  source_policy = [pscustomobject]@{
    reference_video_paths = @($reference)
  }
})

$assetDownloadFailureRequest = Write-TestRequest -Name "$ProjectPrefix-asset-download" -Value ([pscustomobject]@{
  project_id = "$ProjectPrefix-asset-download"
  script_text = "This key paragraph should fail during asset download because the free-resource command is invalid."
  output_dir = "projects"
  voice_config = [pscustomobject]@{
    provider = "local-sapi"
  }
  source_policy = [pscustomobject]@{
    reference_video_paths = @($reference)
    free_resource_command = "__missing_free_resource_command__"
    required_for_key_segments = $true
    key_segment_keywords = @("key")
  }
  max_segment_chars = 120
  render = [pscustomobject]@{
    burn_subtitles = $false
  }
})

$results = @()
$results += Invoke-FailureCase -Name "missing-document" -RequestPath $missingDocumentRequest -ExpectedErrorPattern "document_path|script_text|audio_path"
$results += Invoke-FailureCase -Name "bad-tts" -RequestPath $badTtsRequest -ExpectedErrorPattern "tts\.command|command"
$results += Invoke-FailureCase -Name "asset-download" -RequestPath $assetDownloadFailureRequest -ExpectedErrorPattern "Runner failed|free-resource|missing_free_resource"

[pscustomobject]@{
  status = "passed"
  cases = $results
} | ConvertTo-Json -Depth 8
