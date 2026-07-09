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

function Resolve-InputPath {
  param([string]$Base, [string]$Path)
  if (!$Path) { return "" }
  if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
  return Join-Path $Base $Path
}

function Resolve-ExistingPathOrValue {
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
  param([object]$Value, [string]$Path, [int]$Depth = 16)
  $dir = Split-Path -Parent $Path
  if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth $Depth), [System.Text.UTF8Encoding]::new($false))
}

function Get-DefaultResponsePath {
  param([string]$WorkspacePath)
  $dir = Join-Path $WorkspacePath ".script-broll-video-maker\responses"
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  return (Join-Path $dir ("response-{0}.json" -f (Get-Date -Format "yyyyMMdd-HHmmss")))
}

function Write-FailureResponse {
  param(
    [string]$WorkspacePath,
    [string]$TargetPath,
    [string]$Phase,
    [string]$Message
  )
  if (!$TargetPath) { $TargetPath = Get-DefaultResponsePath -WorkspacePath $WorkspacePath }
  $target = Resolve-InputPath -Base $WorkspacePath -Path $TargetPath
  $response = [pscustomobject]@{
    status = "failed"
    phase = $Phase
    error = $Message
    final_video_path = $null
    final_burned_video_path = $null
    srt_path = $null
    audio_path = $null
    asr_transcript_path = $null
    timeline_path = $null
    preview_contact_sheet_path = $null
    asset_license_report_path = $null
    production_report_path = $null
    segments = @()
    used_assets = @()
    risk_notes = @($Message)
  }
  Write-JsonFile -Value $response -Path $target
  $response | ConvertTo-Json -Depth 16
}

function New-InlineDocument {
  param([string]$WorkspacePath, [string]$Text)
  $dir = Join-Path $WorkspacePath ".script-broll-video-maker\inputs"
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $path = Join-Path $dir ("inline-script-{0}.txt" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
  [System.IO.File]::WriteAllText($path, $Text, [System.Text.UTF8Encoding]::new($false))
  return $path
}

function Get-RiskLevel {
  param([string]$SourceType)
  if ($SourceType -eq "free-resource") { return "low" }
  if ($SourceType -eq "reference_video") { return "high" }
  if ($SourceType -eq "placeholder") { return "high" }
  return "unknown"
}

function Convert-AgentResponse {
  param(
    [object]$Raw,
    [string]$WorkspacePath,
    [string]$TargetPath
  )

  $projectRoot = if ($Raw.project_root) { [string]$Raw.project_root } else { "" }
  $segments = @()
  $usedAssets = @()
  $previewPath = $null
  $asrTranscriptPath = $null
  $licenseReportPath = $null
  $productionReportPath = $null

  if ($projectRoot -and (Test-Path -LiteralPath $projectRoot)) {
    $segmentsPath = Join-Path $projectRoot "text\segments.json"
    $timelinePath = Join-Path $projectRoot "timeline\timeline.json"
    $assetPlanPath = Join-Path $projectRoot "timeline\asset_plan.json"
    $previewCandidate = Join-Path $projectRoot "render\preview_contact_sheet.jpg"
    $asrTranscriptCandidate = Join-Path $projectRoot "text\asr_transcript.json"
    $licenseCandidate = Join-Path $projectRoot "reports\asset_license_report.json"
    $productionCandidate = Join-Path $projectRoot "render\production_report.json"

    if (Test-Path -LiteralPath $previewCandidate) { $previewPath = $previewCandidate }
    if (Test-Path -LiteralPath $asrTranscriptCandidate) { $asrTranscriptPath = $asrTranscriptCandidate }
    if (Test-Path -LiteralPath $licenseCandidate) { $licenseReportPath = $licenseCandidate }
    if (Test-Path -LiteralPath $productionCandidate) { $productionReportPath = $productionCandidate }

    if ((Test-Path -LiteralPath $segmentsPath) -and (Test-Path -LiteralPath $timelinePath)) {
      $segmentJson = Get-Content -LiteralPath $segmentsPath -Raw -Encoding UTF8 | ConvertFrom-Json
      $timelineJson = Get-Content -LiteralPath $timelinePath -Raw -Encoding UTF8 | ConvertFrom-Json
      foreach ($seg in @($segmentJson.segments)) {
        $timelineSeg = @($timelineJson.segments | Where-Object { $_.segment_id -eq $seg.id } | Select-Object -First 1)
        $segments += [pscustomobject]@{
          segment_id = $seg.id
          text = $seg.text
          start_seconds = if ($timelineSeg) { $timelineSeg.start_seconds } else { $null }
          end_seconds = if ($timelineSeg) { $timelineSeg.end_seconds } else { $null }
          is_key_segment = [bool]$seg.is_key_segment
          visual_query = $seg.visual_query
          asr_start_seconds = if ($null -ne $seg.asr_start_seconds) { $seg.asr_start_seconds } else { $null }
          asr_end_seconds = if ($null -ne $seg.asr_end_seconds) { $seg.asr_end_seconds } else { $null }
        }
      }
    }

    if (Test-Path -LiteralPath $assetPlanPath) {
      $assetPlan = Get-Content -LiteralPath $assetPlanPath -Raw -Encoding UTF8 | ConvertFrom-Json
      foreach ($asset in @($assetPlan.segments)) {
        $assetPath = if ($asset.selected_asset) { Resolve-InputPath -Base $projectRoot -Path ([string]$asset.selected_asset) } else { "" }
        $usedAssets += [pscustomobject]@{
          segment_id = $asset.segment_id
          source_type = $asset.source_type
          asset_path = $assetPath
          selection_policy = $asset.selection_policy
          license_record_path = $null
          risk_level = Get-RiskLevel -SourceType ([string]$asset.source_type)
        }
      }
    }
  }

  $riskNotes = @()
  if (@($usedAssets | Where-Object { $_.source_type -eq "reference_video" }).Count -gt 0) {
    $riskNotes += "Reference video footage is high risk unless explicit rights are available."
  }
  if (@($usedAssets | Where-Object { $_.source_type -eq "placeholder" }).Count -gt 0) {
    $riskNotes += "Placeholder footage exists and should not pass production acceptance."
  }
  if (!$licenseReportPath) {
    $riskNotes += "Asset license report was not generated by the MVP runner; assemble it from provider manifests before commercial release."
  }

  $logs = $Raw.logs
  if (!$logs -and ($Raw.runner_log -or $Raw.verifier_log)) {
    $logs = [pscustomobject]@{
      runner = $Raw.runner_log
      verifier = $Raw.verifier_log
    }
  }

  $response = [pscustomobject]@{
    status = $Raw.status
    project_id = $Raw.project_id
    project_root = $projectRoot
    final_video_path = $Raw.final_video
    final_burned_video_path = $Raw.burned_video
    srt_path = $Raw.subtitle
    audio_path = $Raw.narration
    asr_transcript_path = $asrTranscriptPath
    timeline_path = $Raw.timeline
    preview_contact_sheet_path = $previewPath
    asset_license_report_path = $licenseReportPath
    production_report_path = $productionReportPath
    segments = $segments
    used_assets = $usedAssets
    verification = $Raw.verification
    risk_notes = $riskNotes
    error = $Raw.error
    phase = $Raw.phase
    logs = $logs
  }

  if ($TargetPath) {
    Write-JsonFile -Value $response -Path (Resolve-InputPath -Base $WorkspacePath -Path $TargetPath)
  }
  return $response
}

try {
  $skillRoot = Split-Path -Parent $PSCommandPath
  $wrapper = Join-Path $skillRoot "scripts\invoke-script-broll-video-agent.ps1"
  $workspacePath = (Resolve-Path -LiteralPath $Workspace).Path
  $requestFile = Resolve-InputPath -Base $workspacePath -Path $RequestPath
  $request = Get-Content -LiteralPath $requestFile -Raw -Encoding UTF8 | ConvertFrom-Json

  $documentPath = ""
  $audioPath = ""
  if ($request.document_path) {
    $documentPath = Resolve-InputPath -Base $workspacePath -Path ([string]$request.document_path)
  } elseif ($request.script_text) {
    $documentPath = New-InlineDocument -WorkspacePath $workspacePath -Text ([string]$request.script_text)
  }
  if ($request.audio_path) {
    $audioPath = Resolve-InputPath -Base $workspacePath -Path ([string]$request.audio_path)
  }
  if (!$documentPath -and !$audioPath) {
    throw "Request requires document_path, script_text, or audio_path."
  }
  if ($documentPath -and $audioPath) {
    throw "Request must provide either document/script_text or audio_path, not both."
  }

  $aspectRatio = "16:9"
  $aspectRatios = @(Convert-ToStringArray $request.output_aspect_ratios)
  if ($aspectRatios.Count -gt 0) { $aspectRatio = $aspectRatios[0] }
  if ($request.aspect_ratio) { $aspectRatio = [string]$request.aspect_ratio }

  $voiceProvider = if ($request.voice_config.provider) { [string]$request.voice_config.provider } elseif ($request.tts.provider) { [string]$request.tts.provider } else { "local-sapi" }
  $voiceName = if ($request.voice_config.voice) { [string]$request.voice_config.voice } elseif ($request.tts.voice) { [string]$request.tts.voice } else { "" }
  $voiceCommand = if ($request.voice_config.command) { [string]$request.voice_config.command } elseif ($request.tts.command) { [string]$request.tts.command } else { "" }
  if ($voiceCommand) { $voiceCommand = Resolve-ExistingPathOrValue -Base $workspacePath -Value $voiceCommand }

  $asrProvider = if ($request.asr_config.provider) { [string]$request.asr_config.provider } elseif ($request.asr.provider) { [string]$request.asr.provider } else { "none" }
  $asrCommand = if ($request.asr_config.command) { [string]$request.asr_config.command } elseif ($request.asr.command) { [string]$request.asr.command } else { "" }
  $asrLanguage = if ($request.asr_config.language) { [string]$request.asr_config.language } elseif ($request.asr.language) { [string]$request.asr.language } else { "" }
  $transcriptPath = if ($request.transcript_path) { [string]$request.transcript_path } elseif ($request.asr_config.transcript_path) { [string]$request.asr_config.transcript_path } elseif ($request.asr.transcript_path) { [string]$request.asr.transcript_path } else { "" }
  if ($asrCommand) { $asrCommand = Resolve-ExistingPathOrValue -Base $workspacePath -Value $asrCommand }
  if ($transcriptPath) { $transcriptPath = Resolve-InputPath -Base $workspacePath -Path $transcriptPath }

  $sourcePolicy = $request.source_policy
  $referenceVideoPaths = @()
  foreach ($path in (Convert-ToStringArray $sourcePolicy.reference_video_paths)) {
    $referenceVideoPaths += (Resolve-InputPath -Base $workspacePath -Path $path)
  }
  foreach ($path in (Convert-ToStringArray $request.reference_video_paths)) {
    $referenceVideoPaths += (Resolve-InputPath -Base $workspacePath -Path $path)
  }

  $referenceUrls = @()
  foreach ($url in (Convert-ToStringArray $sourcePolicy.reference_urls)) { $referenceUrls += $url }
  foreach ($url in (Convert-ToStringArray $request.reference_urls)) { $referenceUrls += $url }

  $referenceSearchQuery = if ($sourcePolicy.reference_search_query) { [string]$sourcePolicy.reference_search_query } elseif ($request.reference_search_query) { [string]$request.reference_search_query } else { "" }
  $referenceSearchLimit = if ($sourcePolicy.reference_search_limit) { [int]$sourcePolicy.reference_search_limit } elseif ($request.reference_search_limit) { [int]$request.reference_search_limit } else { 1 }
  $autoReferenceSearch = [bool]$sourcePolicy.auto_reference_search -or [bool]$request.auto_reference_search

  $freeResourceCommand = if ($sourcePolicy.free_resource_command) { [string]$sourcePolicy.free_resource_command } elseif ($request.free_resource.command) { [string]$request.free_resource.command } else { "" }
  $freeResourceRoot = if ($sourcePolicy.free_resource_root) { [string]$sourcePolicy.free_resource_root } elseif ($request.free_resource.root) { [string]$request.free_resource.root } else { "" }
  $freeResourceSkillRoot = if ($sourcePolicy.free_resource_skill_root) { [string]$sourcePolicy.free_resource_skill_root } elseif ($request.free_resource.skill_root) { [string]$request.free_resource.skill_root } else { "" }
  $freeResourceConfigPath = if ($sourcePolicy.free_resource_config_path) { [string]$sourcePolicy.free_resource_config_path } elseif ($request.free_resource.config_path) { [string]$request.free_resource.config_path } else { "" }
  if ($freeResourceCommand) { $freeResourceCommand = Resolve-ExistingPathOrValue -Base $workspacePath -Value $freeResourceCommand }
  if ($freeResourceRoot) { $freeResourceRoot = Resolve-InputPath -Base $workspacePath -Path $freeResourceRoot }
  if ($freeResourceSkillRoot) { $freeResourceSkillRoot = Resolve-InputPath -Base $workspacePath -Path $freeResourceSkillRoot }
  if ($freeResourceConfigPath) { $freeResourceConfigPath = Resolve-InputPath -Base $workspacePath -Path $freeResourceConfigPath }

  $keywords = @()
  foreach ($kw in (Convert-ToStringArray $sourcePolicy.key_segment_keywords)) { $keywords += $kw }
  foreach ($kw in (Convert-ToStringArray $request.key_segment_rules.keywords)) { $keywords += $kw }
  $manualIds = @()
  foreach ($id in (Convert-ToStringArray $sourcePolicy.key_segment_ids)) { $manualIds += $id }
  foreach ($id in (Convert-ToStringArray $request.key_segment_rules.manual_ids)) { $manualIds += $id }
  $autoKeySegmentCount = if ($sourcePolicy.auto_key_segment_count) { [int]$sourcePolicy.auto_key_segment_count } elseif ($request.auto_key_segment_count) { [int]$request.auto_key_segment_count } elseif ($request.key_segment_rules.auto_count) { [int]$request.key_segment_rules.auto_count } else { 3 }

  $cookiesPath = if ($request.cookies_path) { [string]$request.cookies_path } elseif ($sourcePolicy.cookies_path) { [string]$sourcePolicy.cookies_path } elseif ($request.youtube.cookies_path) { [string]$request.youtube.cookies_path } else { "" }
  if ($cookiesPath) { $cookiesPath = Resolve-InputPath -Base $workspacePath -Path $cookiesPath }

  $burnSubtitles = $true
  if ($null -ne $request.render.burn_subtitles) { $burnSubtitles = [bool]$request.render.burn_subtitles }

  $normalized = [pscustomobject]@{
    project_id = $request.project_id
    document_path = $documentPath
    audio_path = $audioPath
    transcript_path = $transcriptPath
    output_dir = $(if ($request.output_dir) { [string]$request.output_dir } else { "projects" })
    max_segment_chars = $(if ($request.max_segment_chars) { [int]$request.max_segment_chars } else { 240 })
    tts = [pscustomobject]@{
      provider = $voiceProvider
      voice = $voiceName
      command = $voiceCommand
    }
    asr = [pscustomobject]@{
      provider = $asrProvider
      command = $asrCommand
      language = $asrLanguage
      transcript_path = $transcriptPath
    }
    render = [pscustomobject]@{
      aspect_ratio = $aspectRatio
      burn_subtitles = $burnSubtitles
    }
    reference_urls = $referenceUrls
    reference_video_paths = $referenceVideoPaths
    reference_search = [pscustomobject]@{
      query = $referenceSearchQuery
      limit = $referenceSearchLimit
      auto = $autoReferenceSearch
    }
    youtube = [pscustomobject]@{
      cookies_path = $cookiesPath
    }
    free_resource = [pscustomobject]@{
      command = $freeResourceCommand
      root = $freeResourceRoot
      skill_root = $freeResourceSkillRoot
      config_path = $freeResourceConfigPath
      required_for_key_segments = ([bool]$sourcePolicy.required_for_key_segments -or [bool]$request.free_resource.required_for_key_segments)
    }
    key_segment_rules = [pscustomobject]@{
      keywords = $keywords
      manual_ids = $manualIds
      auto_count = $autoKeySegmentCount
    }
    scene = [pscustomobject]@{
      threshold = $(if ($request.scene.threshold) { [double]$request.scene.threshold } else { 0.35 })
      min_duration_seconds = $(if ($request.scene.min_duration_seconds) { [double]$request.scene.min_duration_seconds } else { 5 })
      preferred_max_duration_seconds = $(if ($request.scene.preferred_max_duration_seconds) { [double]$request.scene.preferred_max_duration_seconds } else { 8 })
      max_duration_seconds = $(if ($request.scene.max_duration_seconds) { [double]$request.scene.max_duration_seconds } else { 15 })
    }
  }

  $workDir = Join-Path $workspacePath ".script-broll-video-maker"
  New-Item -ItemType Directory -Force -Path $workDir | Out-Null
  $normalizedRequestPath = Join-Path $workDir ("normalized-request-{0}.json" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
  Write-JsonFile -Value $normalized -Path $normalizedRequestPath

  $wrapperResponsePath = Join-Path $workDir ("wrapper-response-{0}.json" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
  $psExe = if (Get-Command powershell -ErrorAction SilentlyContinue) { "powershell" } else { "pwsh" }

  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $wrapperOutput = & $psExe -NoProfile -ExecutionPolicy Bypass -File $wrapper -RequestPath $normalizedRequestPath -Workspace $workspacePath -ResponsePath $wrapperResponsePath 2>&1
    $wrapperExitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }

  if (!(Test-Path -LiteralPath $wrapperResponsePath)) {
    throw "Wrapper did not write a response. Output: $($wrapperOutput -join ' ')"
  }

  $rawResponse = Get-Content -LiteralPath $wrapperResponsePath -Raw -Encoding UTF8 | ConvertFrom-Json
  $targetResponsePath = if ($ResponsePath) { $ResponsePath } else { $wrapperResponsePath }
  $response = Convert-AgentResponse -Raw $rawResponse -WorkspacePath $workspacePath -TargetPath $targetResponsePath
  $response | ConvertTo-Json -Depth 16
  exit $wrapperExitCode
} catch {
  $workspaceForFailure = try { (Resolve-Path -LiteralPath $Workspace).Path } catch { (Get-Location).Path }
  Write-FailureResponse -WorkspacePath $workspaceForFailure -TargetPath $ResponsePath -Phase "request-normalization" -Message $_.Exception.Message
  exit 1
}
