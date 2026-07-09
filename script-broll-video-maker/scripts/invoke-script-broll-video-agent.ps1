param(
  [Parameter(Mandatory = $true)]
  [string]$RequestPath,

  [string]$Workspace = (Get-Location).Path,

  [string]$ResponsePath = ""
)

$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function New-Slug {
  param([string]$Text)
  $slug = ($Text -replace '[^a-zA-Z0-9_-]+', '-').Trim('-').ToLowerInvariant()
  if (!$slug) { $slug = "project" }
  return $slug
}

function Resolve-InputPath {
  param([string]$Base, [string]$Path)
  if (!$Path) { return "" }
  if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
  return Join-Path $Base $Path
}

function Resolve-ExistingPathOrCommand {
  param([string]$Base, [string]$Value)
  if (!$Value) { return "" }
  if ([System.IO.Path]::IsPathRooted($Value)) { return $Value }
  $candidate = Join-Path $Base $Value
  if (Test-Path -LiteralPath $candidate) { return $candidate }
  return $Value
}

function Convert-ToStringArray {
  param($Value)
  $items = @()
  if ($null -eq $Value) { return $items }
  foreach ($item in @($Value)) {
    if ($null -ne $item -and "$item".Trim()) { $items += "$item".Trim() }
  }
  return $items
}

function Write-JsonFile {
  param([object]$Value, [string]$Path, [int]$Depth = 12)
  if (!$Path) { return }
  $dir = Split-Path -Parent $Path
  if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth $Depth), [System.Text.UTF8Encoding]::new($false))
}

$script:agentPhase = "preflight"
$script:workspacePathForError = ""
$script:requestFileForError = ""
$script:projectIdForError = ""
$script:projectRootForError = ""
$script:runnerLogForError = ""
$script:verifierLogForError = ""

function Resolve-ResponseTargetForFailure {
  param([string]$WorkspacePath, [string]$ResponsePathValue)
  if ($ResponsePathValue) {
    if ([System.IO.Path]::IsPathRooted($ResponsePathValue)) { return $ResponsePathValue }
    return Join-Path $WorkspacePath $ResponsePathValue
  }
  if ($script:projectRootForError) {
    return Join-Path $script:projectRootForError "logs\agent-response.json"
  }
  $stamp = Get-Date -Format yyyyMMdd-HHmmss
  return Join-Path $WorkspacePath "projects\agent-preflight-failures\$stamp\agent-response.json"
}

function Write-AgentFailureResponse {
  param([System.Management.Automation.ErrorRecord]$ErrorRecord)

  try {
    $workspaceForFailure = $script:workspacePathForError
    if (!$workspaceForFailure) {
      try {
        $workspaceForFailure = (Resolve-Path -LiteralPath $Workspace).Path
      } catch {
        $workspaceForFailure = (Get-Location).Path
      }
    }

    $target = Resolve-ResponseTargetForFailure -WorkspacePath $workspaceForFailure -ResponsePathValue $ResponsePath
    $message = if ($ErrorRecord.Exception -and $ErrorRecord.Exception.Message) { $ErrorRecord.Exception.Message } else { "$ErrorRecord" }
    $errorType = if ($ErrorRecord.Exception) { $ErrorRecord.Exception.GetType().FullName } else { "unknown" }

    $response = [pscustomobject]@{
      status = "failed"
      phase = $script:agentPhase
      project_id = $script:projectIdForError
      project_root = $script:projectRootForError
      request = $script:requestFileForError
      response = $target
      error = $message
      error_type = $errorType
      logs = [pscustomobject]@{
        runner = $script:runnerLogForError
        verifier = $script:verifierLogForError
      }
    }
    Write-JsonFile -Value $response -Path $target -Depth 10
    $response | ConvertTo-Json -Depth 10
  } catch {
    $fallback = [pscustomobject]@{
      status = "failed"
      phase = $script:agentPhase
      error = "Failed to write structured failure response. Original error: $($ErrorRecord.Exception.Message). Response error: $($_.Exception.Message)"
    }
    $fallback | ConvertTo-Json -Depth 6
  }
}

trap {
  Write-AgentFailureResponse -ErrorRecord $_
  exit 1
}

$skillRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$runner = Join-Path $skillRoot "scripts\run-script-broll-video.ps1"
$verifier = Join-Path $skillRoot "scripts\verify-script-broll-video.ps1"

$workspacePath = (Resolve-Path -LiteralPath $Workspace).Path
$script:workspacePathForError = $workspacePath
$requestFile = Resolve-InputPath -Base $workspacePath -Path $RequestPath
$script:requestFileForError = $requestFile
$request = Get-Content -LiteralPath $requestFile -Raw -Encoding UTF8 | ConvertFrom-Json

$script:agentPhase = "request-validation"
$projectId = if ($request.project_id) { [string]$request.project_id } else { "" }
if ($projectId) { $script:projectIdForError = $projectId }

$documentPath = if ($request.document_path) { [string]$request.document_path } elseif ($request.DocumentPath) { [string]$request.DocumentPath } else { "" }
$audioPath = if ($request.audio_path) { [string]$request.audio_path } elseif ($request.AudioPath) { [string]$request.AudioPath } else { "" }
if (!$documentPath -and !$audioPath) { throw "Request is missing document_path or audio_path." }
if ($documentPath -and $audioPath) { throw "Request must provide either document_path or audio_path, not both." }
if ($documentPath) { $documentPath = Resolve-InputPath -Base $workspacePath -Path $documentPath }
if ($audioPath) { $audioPath = Resolve-InputPath -Base $workspacePath -Path $audioPath }

if (!$projectId) {
  $sourceForName = if ($documentPath) { $documentPath } else { $audioPath }
  $projectId = "$(New-Slug ([System.IO.Path]::GetFileNameWithoutExtension($sourceForName)))-$(Get-Date -Format yyyyMMdd-HHmmss)"
}
$script:projectIdForError = $projectId

$outputRoot = if ($request.output_dir) { [string]$request.output_dir } elseif ($request.output_root) { [string]$request.output_root } else { "projects" }
$aspectRatio = if ($request.aspect_ratio) { [string]$request.aspect_ratio } elseif ($request.render.aspect_ratio) { [string]$request.render.aspect_ratio } else { "16:9" }
$voiceName = if ($request.tts.voice) { [string]$request.tts.voice } elseif ($request.voice) { [string]$request.voice } else { "" }
$ttsProvider = if ($request.tts.provider) { [string]$request.tts.provider } else { "local-sapi" }
$ttsCommand = if ($request.tts.command) { [string]$request.tts.command } elseif ($request.tts_command) { [string]$request.tts_command } else { "" }
if (@("local-sapi", "command") -notcontains $ttsProvider) {
  throw "Unsupported TTS provider: $ttsProvider. Supported providers: local-sapi, command."
}
if ($ttsCommand) { $ttsCommand = Resolve-ExistingPathOrCommand -Base $workspacePath -Value $ttsCommand }
if (!$audioPath -and $ttsProvider -eq "command" -and !$ttsCommand) {
  throw "tts.command is required when tts.provider is command."
}

$asrProvider = if ($request.asr.provider) { [string]$request.asr.provider } else { "none" }
$asrCommand = if ($request.asr.command) { [string]$request.asr.command } else { "" }
$asrLanguage = if ($request.asr.language) { [string]$request.asr.language } else { "" }
$transcriptPath = if ($request.transcript_path) { [string]$request.transcript_path } elseif ($request.asr.transcript_path) { [string]$request.asr.transcript_path } else { "" }
if (@("none", "faster-whisper", "command", "mock") -notcontains $asrProvider) {
  throw "Unsupported ASR provider: $asrProvider. Supported providers: none, faster-whisper, command, mock."
}
if ($asrCommand) { $asrCommand = Resolve-ExistingPathOrCommand -Base $workspacePath -Value $asrCommand }
if ($transcriptPath) { $transcriptPath = Resolve-InputPath -Base $workspacePath -Path $transcriptPath }
if ($audioPath -and $asrProvider -eq "command" -and !$asrCommand) {
  throw "asr.command is required when asr.provider is command."
}

$referenceUrls = @()
$referencePaths = @()
foreach ($url in (Convert-ToStringArray $request.reference_urls)) { $referenceUrls += $url }
foreach ($path in (Convert-ToStringArray $request.reference_video_paths)) { $referencePaths += (Resolve-InputPath -Base $workspacePath -Path $path) }
foreach ($ref in @($request.reference_videos)) {
  if ($null -eq $ref) { continue }
  if ($ref -is [string]) {
    $referenceUrls += [string]$ref
    continue
  }
  if ($ref.url) { $referenceUrls += [string]$ref.url }
  if ($ref.path) { $referencePaths += (Resolve-InputPath -Base $workspacePath -Path ([string]$ref.path)) }
}

$keywords = @()
foreach ($kw in (Convert-ToStringArray $request.key_segment_rules.keywords)) { $keywords += $kw }
foreach ($kw in (Convert-ToStringArray $request.keywords)) { $keywords += $kw }
$manualIds = @()
foreach ($id in (Convert-ToStringArray $request.key_segment_rules.manual_ids)) { $manualIds += $id }
$autoKeySegmentCount = if ($request.key_segment_rules.auto_count) { [int]$request.key_segment_rules.auto_count } elseif ($request.auto_key_segment_count) { [int]$request.auto_key_segment_count } else { 3 }

$referenceSearchQuery = if ($request.reference_search_query) { [string]$request.reference_search_query } elseif ($request.reference_search.query) { [string]$request.reference_search.query } else { "" }
$referenceSearchLimit = if ($request.reference_search_limit) { [int]$request.reference_search_limit } elseif ($request.reference_search.limit) { [int]$request.reference_search.limit } else { 1 }
$autoReferenceSearch = [bool]$request.auto_reference_search -or [bool]$request.reference_search.auto

$freeResourceCommand = if ($request.free_resource.command) { [string]$request.free_resource.command } elseif ($request.free_resource_command) { [string]$request.free_resource_command } else { "" }
$freeResourceRoot = if ($request.free_resource.root) { [string]$request.free_resource.root } elseif ($request.free_resource_root) { [string]$request.free_resource_root } else { "" }
$freeResourceSkillRoot = if ($request.free_resource.skill_root) { [string]$request.free_resource.skill_root } elseif ($request.free_resource_skill_root) { [string]$request.free_resource_skill_root } else { "" }
$freeResourceConfigPath = if ($request.free_resource.config_path) { [string]$request.free_resource.config_path } elseif ($request.free_resource_config_path) { [string]$request.free_resource_config_path } else { "" }
$requireFreeResource = [bool]$request.free_resource.required_for_key_segments -or [bool]$request.require_free_resource_for_key_segments
if ($freeResourceCommand) { $freeResourceCommand = Resolve-ExistingPathOrCommand -Base $workspacePath -Value $freeResourceCommand }
if ($freeResourceRoot) { $freeResourceRoot = Resolve-InputPath -Base $workspacePath -Path $freeResourceRoot }
if ($freeResourceSkillRoot) {
  $freeResourceSkillRoot = Resolve-InputPath -Base $workspacePath -Path $freeResourceSkillRoot
  [Environment]::SetEnvironmentVariable("FREE_RESOURCE_SKILL_ROOT", $freeResourceSkillRoot, "Process")
}
if ($freeResourceConfigPath) {
  $freeResourceConfigPath = Resolve-InputPath -Base $workspacePath -Path $freeResourceConfigPath
  [Environment]::SetEnvironmentVariable("FREE_RESOURCE_CONFIG_PATH", $freeResourceConfigPath, "Process")
}

$ytCookiesFromBrowser = if ($request.youtube.cookies_from_browser) { [string]$request.youtube.cookies_from_browser } elseif ($request.yt_dlp.cookies_from_browser) { [string]$request.yt_dlp.cookies_from_browser } else { "" }
$ytCookiesPath = if ($request.youtube.cookies_path) { [string]$request.youtube.cookies_path } elseif ($request.yt_dlp.cookies_path) { [string]$request.yt_dlp.cookies_path } else { "" }
if ($ytCookiesPath) { $ytCookiesPath = Resolve-InputPath -Base $workspacePath -Path $ytCookiesPath }

$maxSegmentChars = if ($request.max_segment_chars) { [int]$request.max_segment_chars } else { 240 }
$sceneThreshold = if ($request.scene.threshold) { [double]$request.scene.threshold } else { 0.35 }
$sceneMinDuration = if ($request.scene.min_duration_seconds) { [double]$request.scene.min_duration_seconds } else { 5 }
$scenePreferredMaxDuration = if ($request.scene.preferred_max_duration_seconds) { [double]$request.scene.preferred_max_duration_seconds } else { 8 }
$sceneMaxDuration = if ($request.scene.max_duration_seconds) { [double]$request.scene.max_duration_seconds } else { 15 }
$burnSubtitles = [bool]$request.render.burn_subtitles

$runnerArgs = @(
  "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $runner,
  "-ProjectId", $projectId,
  "-OutputRoot", $outputRoot,
  "-AspectRatio", $aspectRatio,
  "-MaxSegmentChars", $maxSegmentChars,
  "-SceneThreshold", $sceneThreshold,
  "-SceneMinDuration", $sceneMinDuration,
  "-ScenePreferredMaxDuration", $scenePreferredMaxDuration,
  "-SceneMaxDuration", $sceneMaxDuration,
  "-ReferenceSearchLimit", $referenceSearchLimit,
  "-AutoKeySegmentCount", $autoKeySegmentCount,
  "-TtsProvider", $ttsProvider
)
if ($documentPath) { $runnerArgs += @("-DocumentPath", $documentPath) }
if ($audioPath) { $runnerArgs += @("-AudioPath", $audioPath, "-AsrProvider", $asrProvider) }
if ($audioPath -and $asrCommand) { $runnerArgs += @("-AsrCommand", $asrCommand) }
if ($audioPath -and $asrLanguage) { $runnerArgs += @("-AsrLanguage", $asrLanguage) }
if ($audioPath -and $transcriptPath) { $runnerArgs += @("-TranscriptPath", $transcriptPath) }
if ($ttsProvider -eq "command") { $runnerArgs += @("-TtsCommand", $ttsCommand) }
if ($referenceUrls.Count -gt 0) { $runnerArgs += @("-ReferenceUrl", $referenceUrls) }
if ($referencePaths.Count -gt 0) { $runnerArgs += @("-ReferenceVideoPath", $referencePaths) }
if ($referenceSearchQuery) { $runnerArgs += @("-ReferenceSearchQuery", $referenceSearchQuery) }
if ($autoReferenceSearch) { $runnerArgs += "-AutoReferenceSearch" }
if ($ytCookiesFromBrowser) { $runnerArgs += @("-YtDlpCookiesFromBrowser", $ytCookiesFromBrowser) }
if ($ytCookiesPath) { $runnerArgs += @("-YtDlpCookiesPath", $ytCookiesPath) }
if ($keywords.Count -gt 0) { $runnerArgs += @("-KeySegmentKeywords", ($keywords -join ",")) }
if ($manualIds.Count -gt 0) { $runnerArgs += @("-KeySegmentIds", ($manualIds -join ",")) }
if ($freeResourceRoot) { $runnerArgs += @("-FreeResourceRoot", $freeResourceRoot) }
if ($freeResourceCommand) { $runnerArgs += @("-FreeResourceCommand", $freeResourceCommand) }
if ($requireFreeResource) { $runnerArgs += "-RequireFreeResourceForKeySegments" }
if ($voiceName) { $runnerArgs += @("-VoiceName", $voiceName) }
if ($burnSubtitles) { $runnerArgs += "-BurnSubtitles" }

Set-Location -LiteralPath $workspacePath
$projectRoot = Join-Path $workspacePath (Join-Path $outputRoot $projectId)
if ([System.IO.Path]::IsPathRooted($outputRoot)) {
  $projectRoot = Join-Path $outputRoot $projectId
}
$script:projectRootForError = $projectRoot
$logDir = Join-Path $projectRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$runnerLog = Join-Path $logDir "agent-runner.log"
$verifierLog = Join-Path $logDir "agent-verifier.log"
$script:runnerLogForError = $runnerLog
$script:verifierLogForError = $verifierLog

$script:agentPhase = "runner"
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
  $runnerOutput = & powershell @runnerArgs 2>&1
  $runnerExitCode = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
}
$runnerOutput | Out-File -LiteralPath $runnerLog -Encoding UTF8

if ($runnerExitCode -ne 0) {
  $response = [pscustomobject]@{
    status = "failed"
    phase = "runner"
    project_id = $projectId
    project_root = $projectRoot
    runner_log = $runnerLog
    error = "Runner failed with exit code $runnerExitCode."
  }
  if (!$ResponsePath) { $ResponsePath = Join-Path $logDir "agent-response.json" }
  Write-JsonFile -Value $response -Path (Resolve-InputPath -Base $workspacePath -Path $ResponsePath)
  $response | ConvertTo-Json -Depth 8
  exit 1
}

$resultPath = Join-Path $projectRoot "render\result.json"
if (!(Test-Path -LiteralPath $resultPath)) { throw "Runner completed but result.json is missing: $resultPath" }
$result = Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8 | ConvertFrom-Json

$script:agentPhase = "verification"
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
  $verifierOutput = powershell -NoProfile -ExecutionPolicy Bypass -File $verifier -ProjectRoot $projectRoot 2>&1
  $verifierExitCode = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
}
$verifierOutput | Out-File -LiteralPath $verifierLog -Encoding UTF8

$verificationPath = Join-Path $projectRoot "render\verification.json"
$verification = if (Test-Path -LiteralPath $verificationPath) {
  Get-Content -LiteralPath $verificationPath -Raw -Encoding UTF8 | ConvertFrom-Json
} else {
  [pscustomobject]@{ status = "missing"; failed_count = 1 }
}

$response = [pscustomobject]@{
  status = $(if ($verifierExitCode -eq 0 -and $verification.status -eq "passed") { "completed" } else { "failed" })
  project_id = $projectId
  project_root = $result.project_root
  final_video = $result.final_video
  burned_video = $result.burned_video
  subtitle = $result.subtitle
  narration = $result.narration
  timeline = $result.timeline
  asset_manifest = $result.asset_manifest
  verification = [pscustomobject]@{
    status = $verification.status
    failed_count = $verification.failed_count
    report = $verificationPath
  }
  logs = [pscustomobject]@{
    runner = $runnerLog
    verifier = $verifierLog
  }
}

if (!$ResponsePath) { $ResponsePath = Join-Path $projectRoot "render\agent-response.json" }
Write-JsonFile -Value $response -Path (Resolve-InputPath -Base $workspacePath -Path $ResponsePath)
$response | ConvertTo-Json -Depth 10

if ($response.status -ne "completed") {
  exit 1
}
