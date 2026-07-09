param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRoot,

  [double]$DurationToleranceSeconds = 2.0,

  [switch]$NoThrow
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-StringSha256 {
  param([string]$Text)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
  return ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant()
}

function Get-SubtitleTextLength {
  param([string]$Text)
  if (!$Text) { return 0 }
  return ([regex]::Replace($Text, "\s+", " ").Trim()).Length
}

function Get-ToolPath {
  param([string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $localBin = Join-Path $env:USERPROFILE ".local\bin\$Name.exe"
  if (Test-Path -LiteralPath $localBin) { return $localBin }
  return $null
}

function Resolve-ProjectPath {
  param([string]$Base, [string]$Path)
  if (!$Path) { return $null }
  if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
  return Join-Path $Base $Path
}

$project = (Resolve-Path -LiteralPath $ProjectRoot).Path
$script:checks = @()

function Add-Check {
  param([string]$Name, [bool]$Passed, [string]$Message)
  $script:checks += [pscustomobject]@{
    name = $Name
    passed = $Passed
    message = $Message
  }
}

function Read-JsonFile {
  param([string]$Path)
  return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

$sourcePath = Join-Path $project "text\source_text.txt"
$sourceHashPath = Join-Path $project "text\source_text.sha256"
$segmentsPath = Join-Path $project "text\segments.json"
$audioManifestPath = Join-Path $project "audio\audio_manifest.json"
$srtPath = Join-Path $project "subtitles\final.srt"
$assetPlanPath = Join-Path $project "timeline\asset_plan.json"
$timelinePath = Join-Path $project "timeline\timeline.json"
$resultPath = Join-Path $project "render\result.json"

foreach ($required in @($sourcePath, $sourceHashPath, $segmentsPath, $audioManifestPath, $srtPath, $assetPlanPath, $timelinePath, $resultPath)) {
  Add-Check -Name "exists:$([System.IO.Path]::GetFileName($required))" -Passed (Test-Path -LiteralPath $required) -Message $required
}

if (($script:checks | Where-Object { !$_.passed }).Count -eq 0) {
  $sourceText = [System.IO.File]::ReadAllText($sourcePath, [System.Text.Encoding]::UTF8)
  $expectedSourceHash = (Get-Content -LiteralPath $sourceHashPath -Raw -Encoding UTF8).Trim()
  $actualSourceHash = Get-StringSha256 $sourceText
  Add-Check -Name "source_hash_matches" -Passed ($expectedSourceHash -eq $actualSourceHash) -Message "expected=$expectedSourceHash actual=$actualSourceHash"

  $segmentsDoc = Read-JsonFile $segmentsPath
  $segments = @($segmentsDoc.segments)
  Add-Check -Name "segments_present" -Passed ($segments.Count -gt 0) -Message "count=$($segments.Count)"
  Add-Check -Name "segments_source_hash_matches" -Passed ($segmentsDoc.source_hash -eq $actualSourceHash) -Message "segments_source_hash=$($segmentsDoc.source_hash)"

  $badSegmentHashes = @()
  foreach ($segment in $segments) {
    if ((Get-StringSha256 $segment.text) -ne $segment.text_hash) { $badSegmentHashes += $segment.id }
  }
  Add-Check -Name "segment_hashes_match" -Passed ($badSegmentHashes.Count -eq 0) -Message "bad=$($badSegmentHashes -join ',')"

  $audioManifest = Read-JsonFile $audioManifestPath
  Add-Check -Name "audio_source_hash_matches" -Passed ($audioManifest.source_hash -eq $actualSourceHash) -Message "audio_source_hash=$($audioManifest.source_hash)"
  $audioItems = @($audioManifest.segments)
  Add-Check -Name "audio_segment_count_matches" -Passed ($audioItems.Count -eq $segments.Count) -Message "audio=$($audioItems.Count) segments=$($segments.Count)"

  $missingAudio = @()
  $badAudioHashes = @()
  foreach ($item in $audioItems) {
    $audioPath = Resolve-ProjectPath -Base $project -Path $item.audio_path
    if (!(Test-Path -LiteralPath $audioPath)) { $missingAudio += $item.id }
    $matchingSegment = $segments | Where-Object { $_.id -eq $item.id } | Select-Object -First 1
    if (!$matchingSegment -or $matchingSegment.text_hash -ne $item.text_hash) { $badAudioHashes += $item.id }
  }
  Add-Check -Name "audio_files_exist" -Passed ($missingAudio.Count -eq 0) -Message "missing=$($missingAudio -join ',')"
  Add-Check -Name "audio_text_hashes_match_segments" -Passed ($badAudioHashes.Count -eq 0) -Message "bad=$($badAudioHashes -join ',')"

  $srtText = [System.IO.File]::ReadAllText($srtPath, [System.Text.Encoding]::UTF8)
  $subtitleTextLines = @()
  $multiLineSubtitleCues = @()
  $longSubtitleCues = @()
  $cueBlocks = [regex]::Split($srtText.Trim(), "(?:\r?\n){2,}") | Where-Object { $_.Trim() }
  foreach ($block in $cueBlocks) {
    $lines = @($block -split "\r?\n")
    $cueNumber = $lines[0]
    $textLines = @($lines | Where-Object {
      $_.Trim() -and $_ -notmatch "^\d+$" -and $_ -notmatch "-->"
    })
    if ($textLines.Count -gt 1) { $multiLineSubtitleCues += $cueNumber }
    foreach ($line in $textLines) {
      $subtitleTextLines += $line.Trim()
      if ((Get-SubtitleTextLength $line) -gt 20) {
        $longSubtitleCues += "${cueNumber}:$((Get-SubtitleTextLength $line))"
      }
    }
  }
  $normalizedSrtText = (($subtitleTextLines -join "") -replace "\s+", "")
  $missingSubtitleText = @()
  foreach ($segment in $segments) {
    $normalizedSegmentText = ($segment.text -replace "\s+", "")
    if (!$normalizedSrtText.Contains($normalizedSegmentText)) { $missingSubtitleText += $segment.id }
  }
  Add-Check -Name "subtitles_contain_segment_text" -Passed ($missingSubtitleText.Count -eq 0) -Message "missing=$($missingSubtitleText -join ',')"
  Add-Check -Name "subtitle_cues_are_single_line" -Passed ($multiLineSubtitleCues.Count -eq 0) -Message "bad=$($multiLineSubtitleCues -join ',')"
  Add-Check -Name "subtitle_cue_text_max_20_chars" -Passed ($longSubtitleCues.Count -eq 0) -Message "bad=$($longSubtitleCues -join ',')"

  $assetPlan = Read-JsonFile $assetPlanPath
  $assetSegments = @($assetPlan.segments)
  Add-Check -Name "asset_segment_count_matches" -Passed ($assetSegments.Count -eq $segments.Count) -Message "assets=$($assetSegments.Count) segments=$($segments.Count)"
  $missingAssets = @()
  foreach ($asset in $assetSegments) {
    $assetPath = Resolve-ProjectPath -Base $project -Path $asset.selected_asset
    if (!(Test-Path -LiteralPath $assetPath)) { $missingAssets += $asset.segment_id }
  }
  Add-Check -Name "selected_assets_exist" -Passed ($missingAssets.Count -eq 0) -Message "missing=$($missingAssets -join ',')"

  $timeline = Read-JsonFile $timelinePath
  $timelineSegments = @($timeline.segments)
  Add-Check -Name "timeline_source_hash_matches" -Passed ($timeline.source_hash -eq $actualSourceHash) -Message "timeline_source_hash=$($timeline.source_hash)"
  Add-Check -Name "timeline_segment_count_matches" -Passed ($timelineSegments.Count -eq $segments.Count) -Message "timeline=$($timelineSegments.Count) segments=$($segments.Count)"
  $missingTimelineFiles = @()
  foreach ($entry in $timelineSegments) {
    foreach ($pathValue in @($entry.audio, $entry.visual)) {
      $resolved = Resolve-ProjectPath -Base $project -Path $pathValue
      if (!(Test-Path -LiteralPath $resolved)) { $missingTimelineFiles += "$($entry.segment_id):$pathValue" }
    }
  }
  Add-Check -Name "timeline_files_exist" -Passed ($missingTimelineFiles.Count -eq 0) -Message "missing=$($missingTimelineFiles -join ',')"

  $result = Read-JsonFile $resultPath
  $finalVideo = Resolve-ProjectPath -Base $project -Path $result.final_video
  Add-Check -Name "final_video_exists" -Passed (Test-Path -LiteralPath $finalVideo) -Message $finalVideo

  if (Test-Path -LiteralPath $finalVideo) {
    $ffprobe = Get-ToolPath "ffprobe"
    Add-Check -Name "ffprobe_available" -Passed ([bool]$ffprobe) -Message $(if ($ffprobe) { $ffprobe } else { "missing" })
    if ($ffprobe) {
      $probeJson = & $ffprobe -v error -show_entries stream=index,codec_type,codec_name,width,height:format=duration -of json "$finalVideo"
      $probe = $probeJson | ConvertFrom-Json
      $streamTypes = @($probe.streams | ForEach-Object { $_.codec_type })
      Add-Check -Name "final_has_video_stream" -Passed ($streamTypes -contains "video") -Message ($streamTypes -join ",")
      Add-Check -Name "final_has_audio_stream" -Passed ($streamTypes -contains "audio") -Message ($streamTypes -join ",")
      Add-Check -Name "final_has_subtitle_stream" -Passed ($streamTypes -contains "subtitle") -Message ($streamTypes -join ",")
      $finalDuration = [double]::Parse($probe.format.duration, [Globalization.CultureInfo]::InvariantCulture)
      $audioDuration = [double]$audioManifest.total_duration_seconds
      $delta = [math]::Abs($finalDuration - $audioDuration)
      Add-Check -Name "final_duration_matches_audio" -Passed ($delta -le $DurationToleranceSeconds) -Message "final=$finalDuration audio=$audioDuration delta=$delta"
    }
  }
}

$failed = @($script:checks | Where-Object { !$_.passed })
$report = [pscustomobject]@{
  status = $(if ($failed.Count -eq 0) { "passed" } else { "failed" })
  project_root = $project
  check_count = $script:checks.Count
  failed_count = $failed.Count
  checks = $script:checks
}

$reportPath = Join-Path $project "render\verification.json"
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding UTF8
$report | ConvertTo-Json -Depth 8

if ($failed.Count -gt 0 -and !$NoThrow) {
  exit 1
}
