param(
  [Parameter(Mandatory = $true)]
  [string]$RequestPath,

  [Parameter(Mandatory = $true)]
  [string]$OutputDir,

  [ValidateSet("auto", "pexels", "pixabay")]
  [string]$Provider = "auto",

  [int]$PerPage = 10,

  [int]$TimeoutSeconds = 60,

  [string]$ConfigPath = "",

  [string]$FreeResourceSkillRoot = "",

  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Import-DotEnvKeys {
  param(
    [string[]]$Paths,
    [string[]]$AllowedKeys
  )
  foreach ($path in $Paths) {
    if (!$path -or !(Test-Path -LiteralPath $path)) { continue }
    foreach ($line in [System.IO.File]::ReadAllLines($path)) {
      $trimmed = $line.Trim()
      if (!$trimmed -or $trimmed.StartsWith("#")) { continue }
      if ($trimmed.StartsWith("export ")) { $trimmed = $trimmed.Substring(7).Trim() }
      if ($trimmed -notmatch '^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') { continue }
      $key = $Matches[1]
      if ($AllowedKeys -notcontains $key) { continue }
      if ([Environment]::GetEnvironmentVariable($key, "Process")) { continue }
      $value = $Matches[2].Trim()
      if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
      }
      [Environment]::SetEnvironmentVariable($key, $value, "Process")
    }
  }
}

function Write-Utf8File {
  param([string]$Path, [string]$Text)
  $dir = Split-Path -Parent $Path
  if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Write-Json {
  param([object]$Value, [string]$Path, [int]$Depth = 12)
  Write-Utf8File -Path $Path -Text ($Value | ConvertTo-Json -Depth $Depth)
}

function Import-FreeResourceConfig {
  param([string[]]$Paths)
  foreach ($path in $Paths) {
    if (!$path -or !(Test-Path -LiteralPath $path)) { continue }
    try {
      $config = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
      if (!$env:PEXELS_API_KEY -and $config.pexels.api_key) {
        [Environment]::SetEnvironmentVariable("PEXELS_API_KEY", [string]$config.pexels.api_key, "Process")
      }
      if (!$env:PIXABAY_API_KEY -and $config.pixabay.api_key) {
        [Environment]::SetEnvironmentVariable("PIXABAY_API_KEY", [string]$config.pixabay.api_key, "Process")
      }
    } catch {
      throw "Failed to read free-resource config at ${path}: $($_.Exception.Message)"
    }
  }
}

function Get-AspectMode {
  param([string]$AspectRatio)
  if ($AspectRatio -eq "9:16") { return "portrait" }
  if ($AspectRatio -eq "16:9") { return "landscape" }
  return "all"
}

function Test-AspectMatch {
  param([int]$Width, [int]$Height, [string]$AspectMode)
  if ($AspectMode -eq "landscape") { return ($Width -ge $Height) }
  if ($AspectMode -eq "portrait") { return ($Height -ge $Width) }
  return $true
}

function Get-SafeFileStem {
  param([string]$Text)
  $stem = ($Text -replace '[^a-zA-Z0-9_-]+', '-').Trim('-').ToLowerInvariant()
  if (!$stem) { return "asset" }
  if ($stem.Length -gt 80) { return $stem.Substring(0, 80).Trim('-') }
  return $stem
}

function Invoke-JsonRequest {
  param(
    [string]$Uri,
    [hashtable]$Headers = @{}
  )
  return Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -TimeoutSec $TimeoutSeconds
}

function Get-BunPath {
  $cmd = Get-Command bun -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return ""
}

function Get-FreeResourceSkillRoot {
  if ($env:FREE_RESOURCE_SKILL_ROOT -and (Test-Path -LiteralPath $env:FREE_RESOURCE_SKILL_ROOT -PathType Container)) {
    return (Resolve-Path -LiteralPath $env:FREE_RESOURCE_SKILL_ROOT).Path
  }
  return ""
}

function Invoke-FreeResourceCliJson {
  param(
    [string]$SkillRoot,
    [string]$Provider,
    [string[]]$Arguments,
    [string]$OutputJson
  )
  $bun = Get-BunPath
  if (!$bun) { throw "bun is not available for free-resource CLI." }
  $script = Join-Path $SkillRoot "scripts\$Provider.ts"
  if (!(Test-Path -LiteralPath $script)) { throw "free-resource script missing: $script" }

  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $cliOutput = @(& $bun $script @Arguments --output $OutputJson 2>&1)
    $cliExitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  if ($cliExitCode -ne 0) {
    throw "free-resource $Provider CLI failed with code $cliExitCode. $($cliOutput -join ' ')"
  }
  if (!(Test-Path -LiteralPath $OutputJson)) { throw "free-resource $Provider CLI did not create output JSON: $OutputJson" }
  return Get-Content -LiteralPath $OutputJson -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Select-PexelsVideoFile {
  param([object]$Video, [string]$AspectMode)
  $targetPixels = 1280 * 720
  $files = @($Video.video_files) |
    Where-Object { $_.file_type -eq "video/mp4" -and (Test-AspectMatch -Width ([int]$_.width) -Height ([int]$_.height) -AspectMode $AspectMode) } |
    Sort-Object `
      @{ Expression = { if ([int]$_.width -ge 1280 -and [int]$_.height -ge 720) { 0 } else { 1 } } }, `
      @{ Expression = { [math]::Abs(([int]$_.width * [int]$_.height) - $targetPixels) } }, `
      @{ Expression = { if ($_.size) { [int64]$_.size } else { [int64]::MaxValue } } }
  if (!$files -or $files.Count -eq 0) { return $null }
  return $files[0]
}

function Search-FreeResourceCliPexelsVideos {
  param([object]$Request, [string]$SkillRoot, [string]$AspectMode)
  $orientation = if ($AspectMode -eq "landscape") { "landscape" } elseif ($AspectMode -eq "portrait") { "portrait" } else { "" }
  $searchPath = Join-Path $OutputDir "pexels-cli-search.json"
  $args = @("search-videos", "--query", [string]$Request.query, "--per-page", [string]$PerPage)
  if ($orientation) { $args += @("--orientation", $orientation) }
  $response = Invoke-FreeResourceCliJson -SkillRoot $SkillRoot -Provider "pexels" -Arguments $args -OutputJson $searchPath
  $candidates = @()
  foreach ($video in @($response.videos)) {
    $best = Select-PexelsVideoFile -Video $video -AspectMode $AspectMode
    if (!$best) { continue }
    $pixels = [int]$best.width * [int]$best.height
    $candidates += [pscustomobject]@{
      provider = "pexels"
      id = [string]$video.id
      link = $best.link
      page_url = $video.url
      width = [int]$best.width
      height = [int]$best.height
      duration_seconds = [double]$video.duration
      license = "pexels"
      attribution = $(if ($video.user.name) { $video.user.name } else { "" })
      score = $pixels
      download_runner = "free-resource-cli"
      download_script = Join-Path $SkillRoot "scripts\pexels.ts"
    }
  }
  return $candidates
}

function Search-FreeResourceCliPixabayVideos {
  param([object]$Request, [string]$SkillRoot, [string]$AspectMode)
  $searchPath = Join-Path $OutputDir "pixabay-cli-search.json"
  $response = Invoke-FreeResourceCliJson -SkillRoot $SkillRoot -Provider "pixabay" -Arguments @("search-videos", "--query", [string]$Request.query, "--per-page", [string][math]::Max(5, $PerPage)) -OutputJson $searchPath
  $candidates = @()
  foreach ($hit in @($response.hits)) {
    foreach ($option in @("medium", "small", "tiny", "large")) {
      $video = $hit.videos.$option
      if (!$video) { continue }
      if (!(Test-AspectMatch -Width ([int]$video.width) -Height ([int]$video.height) -AspectMode $AspectMode)) { continue }
      $pixels = [int]$video.width * [int]$video.height
      $candidates += [pscustomobject]@{
        provider = "pixabay"
        id = [string]$hit.id
        link = $video.url
        page_url = $hit.pageURL
        width = [int]$video.width
        height = [int]$video.height
        duration_seconds = [double]$hit.duration
        license = "pixabay"
        attribution = $(if ($hit.user) { $hit.user } else { "" })
        score = $pixels
        download_runner = "free-resource-cli"
        download_script = Join-Path $SkillRoot "scripts\pixabay.ts"
      }
      break
    }
  }
  return $candidates
}

function Search-PexelsVideos {
  param([object]$Request, [string]$ApiKey, [string]$AspectMode)
  if (!$ApiKey) { return @() }

  $orientation = ""
  if ($AspectMode -eq "landscape") { $orientation = "&orientation=landscape" }
  if ($AspectMode -eq "portrait") { $orientation = "&orientation=portrait" }

  $query = [Uri]::EscapeDataString($Request.query)
  $uri = "https://api.pexels.com/v1/videos/search?query=$query&per_page=$PerPage$orientation"
  $headers = @{ Authorization = $ApiKey }
  $response = Invoke-JsonRequest -Uri $uri -Headers $headers
  $candidates = @()

  foreach ($video in @($response.videos)) {
    $files = @($video.video_files) |
      Where-Object { $_.file_type -eq "video/mp4" -and (Test-AspectMatch -Width ([int]$_.width) -Height ([int]$_.height) -AspectMode $AspectMode) } |
      Sort-Object @{ Expression = { [int]$_.width * [int]$_.height }; Descending = $true }

    if (!$files -or $files.Count -eq 0) { continue }
    $best = $files[0]
    $candidates += [pscustomobject]@{
      provider = "pexels"
      id = [string]$video.id
      link = $best.link
      page_url = $video.url
      width = [int]$best.width
      height = [int]$best.height
      duration_seconds = [double]$video.duration
      license = "pexels"
      attribution = $(if ($video.user.name) { $video.user.name } else { "" })
      score = ([int]$best.width * [int]$best.height)
    }
  }
  return $candidates
}

function Search-PixabayVideos {
  param([object]$Request, [string]$ApiKey, [string]$AspectMode)
  if (!$ApiKey) { return @() }

  $query = [Uri]::EscapeDataString($Request.query)
  $uri = "https://pixabay.com/api/videos/?key=$ApiKey&q=$query&per_page=$PerPage&safesearch=true&order=popular"
  $response = Invoke-JsonRequest -Uri $uri
  $candidates = @()

  foreach ($hit in @($response.hits)) {
    $videoOptions = @("large", "medium", "small", "tiny")
    foreach ($option in $videoOptions) {
      $video = $hit.videos.$option
      if (!$video) { continue }
      if (!(Test-AspectMatch -Width ([int]$video.width) -Height ([int]$video.height) -AspectMode $AspectMode)) { continue }
      $candidates += [pscustomobject]@{
        provider = "pixabay"
        id = [string]$hit.id
        link = $video.url
        page_url = $hit.pageURL
        width = [int]$video.width
        height = [int]$video.height
        duration_seconds = [double]$hit.duration
        license = "pixabay"
        attribution = $(if ($hit.user) { $hit.user } else { "" })
        score = ([int]$video.width * [int]$video.height)
      }
      break
    }
  }
  return $candidates
}

function Save-RemoteAsset {
  param([object]$Candidate, [string]$TargetDir, [string]$SegmentId)
  $stem = Get-SafeFileStem "$($Candidate.provider)-$SegmentId-$($Candidate.id)"
  $target = Join-Path $TargetDir "$stem.mp4"
  if ($Candidate.download_runner -eq "free-resource-cli" -and $Candidate.download_script) {
    $bun = Get-BunPath
    if (!$bun) { throw "bun is not available for free-resource CLI download." }
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
      $downloadOutput = @(& $bun $Candidate.download_script download --url $Candidate.link --output $target 2>&1)
      $downloadExitCode = $LASTEXITCODE
    } finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($downloadExitCode -ne 0) {
      throw "free-resource CLI download failed with code $downloadExitCode. $($downloadOutput -join ' ')"
    }
  } else {
    Invoke-WebRequest -Uri $Candidate.link -OutFile $target -TimeoutSec $TimeoutSeconds
  }
  if (!(Test-Path -LiteralPath $target)) { throw "Downloaded file missing: $target" }
  if ((Get-Item -LiteralPath $target).Length -le 0) { throw "Downloaded file is empty: $target" }
  return $target
}

$request = Get-Content -LiteralPath $RequestPath -Raw -Encoding UTF8 | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$cwdPath = (Resolve-Path -LiteralPath ".").Path
Import-DotEnvKeys -Paths @(
  (Join-Path $cwdPath ".env"),
  (Join-Path $env:USERPROFILE ".codex\.env"),
  (Join-Path $env:USERPROFILE ".agents\.env")
) -AllowedKeys @("PEXELS_API_KEY", "PIXABAY_API_KEY", "FREE_RESOURCE_SKILL_ROOT", "FREE_RESOURCE_CONFIG_PATH")

if ($FreeResourceSkillRoot) {
  [Environment]::SetEnvironmentVariable("FREE_RESOURCE_SKILL_ROOT", $FreeResourceSkillRoot, "Process")
}
if ($ConfigPath) {
  [Environment]::SetEnvironmentVariable("FREE_RESOURCE_CONFIG_PATH", $ConfigPath, "Process")
}

$configCandidates = @()
if ($env:FREE_RESOURCE_CONFIG_PATH) { $configCandidates += $env:FREE_RESOURCE_CONFIG_PATH }
if ($env:FREE_RESOURCE_SKILL_ROOT) { $configCandidates += (Join-Path $env:FREE_RESOURCE_SKILL_ROOT "config.json") }
Import-FreeResourceConfig -Paths $configCandidates

if (!$request.query) { throw "Request is missing query." }
if (!$request.segment_id) { throw "Request is missing segment_id." }

$pexelsKey = $env:PEXELS_API_KEY
$pixabayKey = $env:PIXABAY_API_KEY
$aspectMode = Get-AspectMode $request.aspect_ratio
$providers = if ($Provider -eq "auto") { @("pexels", "pixabay") } else { @($Provider) }
$freeResourceSkillRoot = Get-FreeResourceSkillRoot

$searchResults = @()
$errors = @()
foreach ($p in $providers) {
  try {
    $providerResults = @()
    if ($freeResourceSkillRoot) {
      if ($p -eq "pexels") {
        $providerResults = @(Search-FreeResourceCliPexelsVideos -Request $request -SkillRoot $freeResourceSkillRoot -AspectMode $aspectMode)
      } elseif ($p -eq "pixabay") {
        $providerResults = @(Search-FreeResourceCliPixabayVideos -Request $request -SkillRoot $freeResourceSkillRoot -AspectMode $aspectMode)
      }
    }
    if ($providerResults.Count -eq 0) {
      if ($p -eq "pexels") {
        $providerResults = @(Search-PexelsVideos -Request $request -ApiKey $pexelsKey -AspectMode $aspectMode)
      } elseif ($p -eq "pixabay") {
        $providerResults = @(Search-PixabayVideos -Request $request -ApiKey $pixabayKey -AspectMode $aspectMode)
      }
    }
    $searchResults += $providerResults
  } catch {
    $errors += [pscustomobject]@{ provider = $p; error = $_.Exception.Message }
  }
}

$manifestPath = Join-Path $OutputDir "free-resource-api-manifest.json"

if ($DryRun) {
  Write-Json ([pscustomobject]@{
    status = "dry-run"
    segment_id = $request.segment_id
    query = $request.query
    provider = $Provider
    has_pexels_key = [bool]$pexelsKey
    has_pixabay_key = [bool]$pixabayKey
    free_resource_skill_root = $freeResourceSkillRoot
    aspect_mode = $aspectMode
    candidate_count = @($searchResults).Count
    errors = $errors
  }) $manifestPath
  Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8
  exit 0
}

if (@($searchResults).Count -eq 0) {
  $missing = @()
  if ($providers -contains "pexels" -and !$pexelsKey) { $missing += "PEXELS_API_KEY" }
  if ($providers -contains "pixabay" -and !$pixabayKey) { $missing += "PIXABAY_API_KEY" }
  $message = if ($missing.Count -gt 0) {
    "No free-resource candidates. Missing API key(s): $($missing -join ', ')."
  } else {
    "No free-resource candidates found for query: $($request.query)"
  }
  Write-Json ([pscustomobject]@{
    status = "failed"
    segment_id = $request.segment_id
    query = $request.query
    provider = $Provider
    errors = $errors
    message = $message
  }) $manifestPath
  throw $message
}

$selected = @($searchResults | Sort-Object @{ Expression = { $_.score }; Descending = $true })[0]
$assetPath = Save-RemoteAsset -Candidate $selected -TargetDir $OutputDir -SegmentId $request.segment_id

$manifest = [pscustomobject]@{
  status = "completed"
  segment_id = $request.segment_id
  query = $request.query
  selected = [pscustomobject]@{
    provider = $selected.provider
    id = $selected.id
    asset_path = $assetPath
    page_url = $selected.page_url
    width = $selected.width
    height = $selected.height
    duration_seconds = $selected.duration_seconds
    license = $selected.license
    attribution = $selected.attribution
    download_runner = $(if ($selected.download_runner) { $selected.download_runner } else { "direct-api" })
  }
  candidate_count = @($searchResults).Count
  errors = $errors
  downloaded_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $manifest $manifestPath
$manifest | ConvertTo-Json -Depth 12
