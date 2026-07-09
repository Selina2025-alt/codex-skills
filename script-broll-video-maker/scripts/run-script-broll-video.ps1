param(
  [string]$DocumentPath = "",

  [string]$AudioPath = "",

  [ValidateSet("none", "faster-whisper", "command", "mock")]
  [string]$AsrProvider = "none",

  [string]$AsrCommand = "",

  [string]$AsrLanguage = "",

  [string]$TranscriptPath = "",

  [string[]]$ReferenceUrl = @(),

  [string[]]$ReferenceVideoPath = @(),

  [string]$ReferenceSearchQuery = "",

  [int]$ReferenceSearchLimit = 1,

  [switch]$AutoReferenceSearch,

  [string]$YtDlpCookiesFromBrowser = "",

  [string]$YtDlpCookiesPath = "",

  [string]$OutputRoot = "projects",

  [string]$ProjectId = "",

  [string]$AspectRatio = "16:9",

  [string]$KeySegmentKeywords = "",

  [string]$KeySegmentIds = "",

  [int]$AutoKeySegmentCount = 3,

  [switch]$DisableAutoKeySegments,

  [string]$FreeResourceRoot = "",

  [string]$FreeResourceCommand = "",

  [switch]$RequireFreeResourceForKeySegments,

  [ValidateSet("local-sapi", "command")]
  [string]$TtsProvider = "local-sapi",

  [string]$TtsCommand = "",

  [string]$VoiceName = "",

  [int]$MaxSegmentChars = 240,

  [double]$SceneThreshold = 0.35,

  [double]$SceneMinDuration = 5,

  [double]$ScenePreferredMaxDuration = 8,

  [double]$SceneMaxDuration = 15,

  [switch]$BurnSubtitles
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

function Get-StringSha256 {
  param([string]$Text)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
  return ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant()
}

function Write-Utf8File {
  param([string]$Path, [string]$Text)
  $dir = Split-Path -Parent $Path
  if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Write-Json {
  param([object]$Value, [string]$Path, [int]$Depth = 10)
  Write-Utf8File -Path $Path -Text ($Value | ConvertTo-Json -Depth $Depth)
}

function Get-RelativePath {
  param([string]$BasePath, [string]$Path)
  $base = [System.IO.Path]::GetFullPath($BasePath)
  $target = [System.IO.Path]::GetFullPath($Path)
  if (!$base.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
    $base += [System.IO.Path]::DirectorySeparatorChar
  }
  $baseUri = [Uri]::new($base)
  $targetUri = [Uri]::new($target)
  return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
}

function Get-ToolPath {
  param([string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $localBin = Join-Path $env:USERPROFILE ".local\bin\$Name.exe"
  if (Test-Path -LiteralPath $localBin) { return $localBin }
  $workspaceTool = Join-Path (Resolve-Path -LiteralPath ".") "tools\$Name.exe"
  if (Test-Path -LiteralPath $workspaceTool) { return $workspaceTool }
  return $null
}

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

function Format-SrtTime {
  param([double]$Seconds)
  $ts = [TimeSpan]::FromSeconds([math]::Max(0.0, [double]$Seconds))
  return "{0:00}:{1:00}:{2:00},{3:000}" -f [math]::Floor($ts.TotalHours), $ts.Minutes, $ts.Seconds, $ts.Milliseconds
}

function Get-SubtitleTextLength {
  param([string]$Text)
  if (!$Text) { return 0 }
  return ([regex]::Replace($Text, "\s+", " ").Trim()).Length
}

function Test-SubtitleBoundaryChar {
  param([char]$Char)
  $code = [int]$Char
  return ($code -in @(
    0x3002, 0xFF01, 0xFF1F, 0xFF1B, 0xFF0C, 0x3001, 0xFF1A,
    0x002E, 0x0021, 0x003F, 0x003B, 0x002C, 0x003A
  ))
}

function Test-SubtitleBoundaryAhead {
  param(
    [string]$Text,
    [int]$StartIndex,
    [int]$MaxVisibleChars
  )
  if ($MaxVisibleChars -le 0) { return $false }
  $visible = 0
  for ($i = $StartIndex; $i -lt $Text.Length; $i++) {
    $char = $Text[$i]
    if (Test-SubtitleBoundaryChar $char) { return $true }
    if ([char]::IsWhiteSpace($char)) { return $true }
    if (![char]::IsWhiteSpace($char)) { $visible += 1 }
    if ($visible -ge $MaxVisibleChars) { break }
  }
  return $false
}

function Add-SubtitleChunk {
  param(
    [System.Collections.Generic.List[string]]$Chunks,
    [string]$Text
  )
  $clean = [regex]::Replace($Text, "\s+", " ").Trim()
  if ($clean) { $Chunks.Add($clean) }
}

function Split-SubtitleText {
  param(
    [string]$Text,
    [int]$TargetChars = 14,
    [int]$MaxChars = 20,
    [int]$MinChars = 10
  )
  $normalized = [regex]::Replace($Text, "\s+", " ").Trim()
  $chunks = [System.Collections.Generic.List[string]]::new()
  if (!$normalized) { return @() }

  $buffer = [System.Text.StringBuilder]::new()
  for ($i = 0; $i -lt $normalized.Length; $i++) {
    $char = $normalized[$i]
    [void]$buffer.Append($char)
    $current = $buffer.ToString()
    $length = Get-SubtitleTextLength $current
    if ($length -ge $MaxChars) {
      Add-SubtitleChunk -Chunks $chunks -Text $current
      [void]$buffer.Clear()
      continue
    }
    if ($length -ge $MinChars -and (Test-SubtitleBoundaryChar $char)) {
      Add-SubtitleChunk -Chunks $chunks -Text $current
      [void]$buffer.Clear()
      continue
    }
    if ($length -ge $TargetChars -and [char]::IsWhiteSpace($char)) {
      Add-SubtitleChunk -Chunks $chunks -Text $current
      [void]$buffer.Clear()
      continue
    }
    if ($length -ge $TargetChars) {
      $remainingVisibleChars = $MaxChars - $length
      if (!(Test-SubtitleBoundaryAhead -Text $normalized -StartIndex ($i + 1) -MaxVisibleChars $remainingVisibleChars)) {
        Add-SubtitleChunk -Chunks $chunks -Text $current
        [void]$buffer.Clear()
        continue
      }
    }
  }

  if ($buffer.Length -gt 0) {
    Add-SubtitleChunk -Chunks $chunks -Text $buffer.ToString()
  }
  return @($chunks)
}

function Read-SourceText {
  param([string]$Path)
  $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
  if ($ext -in @(".txt", ".md")) {
    return [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path), [System.Text.Encoding]::UTF8)
  }
  if ($ext -eq ".docx") {
    return Read-DocxText $Path
  }
  if ($ext -eq ".pdf") {
    return Read-PdfText $Path
  }
  throw "Unsupported document format: $ext. Supported MVP formats: .txt, .md, .docx, .pdf with pdftotext."
}

function Read-DocxText {
  param([string]$Path)
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $resolved = (Resolve-Path -LiteralPath $Path).Path
  $archive = [System.IO.Compression.ZipFile]::OpenRead($resolved)
  try {
    $entry = $archive.Entries | Where-Object { $_.FullName -eq "word/document.xml" } | Select-Object -First 1
    if (!$entry) { throw "word/document.xml not found in DOCX." }
    $reader = [System.IO.StreamReader]::new($entry.Open(), [System.Text.Encoding]::UTF8)
    try {
      [xml]$xml = $reader.ReadToEnd()
    } finally {
      $reader.Dispose()
    }
    $ns = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
    $ns.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
    $paragraphs = @()
    foreach ($p in $xml.SelectNodes("//w:body/w:p", $ns)) {
      $texts = @()
      foreach ($t in $p.SelectNodes(".//w:t", $ns)) {
        $texts += $t.InnerText
      }
      $line = ($texts -join "")
      if ($line.Trim()) { $paragraphs += $line.Trim() }
    }
    return ($paragraphs -join "`r`n`r`n")
  } finally {
    $archive.Dispose()
  }
}

function Read-PdfText {
  param([string]$Path)
  $pdftotext = Get-ToolPath "pdftotext"
  if (!$pdftotext) {
    throw "PDF text extraction requires pdftotext. Install Poppler or convert the PDF to .txt/.md first."
  }
  $temp = Join-Path ([System.IO.Path]::GetTempPath()) ("script-broll-pdf-" + [Guid]::NewGuid().ToString("N") + ".txt")
  & $pdftotext -layout -enc UTF-8 "$Path" "$temp"
  if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $temp)) {
    throw "pdftotext failed for PDF: $Path"
  }
  try {
    return [System.IO.File]::ReadAllText($temp, [System.Text.Encoding]::UTF8)
  } finally {
    Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
  }
}

function Split-IntoSegments {
  param([string]$Text, [int]$MaxChars, [string[]]$Keywords)
  $parts = [System.Collections.Generic.List[string]]::new()
  $paragraphs = [regex]::Split($Text, "(\r?\n\s*\r?\n)+") | Where-Object { $_ -and $_.Trim().Length -gt 0 }
  foreach ($paragraph in $paragraphs) {
    $p = $paragraph.Trim()
    if ($p.Length -le $MaxChars) {
      $parts.Add($p)
      continue
    }
    $sentences = [regex]::Split($p, "(?<=[。！？.!?])\s*")
    $buffer = ""
    foreach ($sentence in $sentences) {
      $s = $sentence.Trim()
      if (!$s) { continue }
      if (($buffer.Length + $s.Length + 1) -le $MaxChars) {
        if ($buffer) { $buffer += " " }
        $buffer += $s
      } else {
        if ($buffer) { $parts.Add($buffer) }
        if ($s.Length -le $MaxChars) {
          $buffer = $s
        } else {
          $i = 0
          while ($i -lt $s.Length) {
            $len = Get-SafeTextCutLength -Text $s -StartIndex $i -MaxChars $MaxChars
            $parts.Add($s.Substring($i, $len))
            $i += $len
          }
          $buffer = ""
        }
      }
    }
    if ($buffer) { $parts.Add($buffer) }
  }

  $segments = @()
  $index = 1
  foreach ($part in $parts) {
    $id = "seg_{0:000}" -f $index
    $isKey = $false
    foreach ($kw in $Keywords) {
      if ($kw -and $part.IndexOf($kw, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $isKey = $true
      }
    }
    $segments += [pscustomobject]@{
      id = $id
      order = $index
      text = $part
      text_hash = Get-StringSha256 $part
      is_key_segment = $isKey
      visual_query = New-VisualQuery $part
      preferred_source = $(if ($isKey) { "free-resource" } else { "reference_video" })
    }
    $index += 1
  }
  return $segments
}

function Get-SafeTextCutLength {
  param([string]$Text, [int]$StartIndex, [int]$MaxChars)
  $remaining = $Text.Length - $StartIndex
  if ($remaining -le $MaxChars) { return $remaining }

  $minChars = [Math]::Max(20, [Math]::Floor($MaxChars * 0.6))
  for ($offset = $MaxChars - 1; $offset -ge $minChars; $offset--) {
    $char = $Text[$StartIndex + $offset]
    if ([char]::IsWhiteSpace($char) -or (Test-SubtitleBoundaryChar $char)) {
      return ($offset + 1)
    }
  }

  $cut = $MaxChars
  while ($cut -gt $minChars) {
    $prev = $Text[$StartIndex + $cut - 1]
    $next = $Text[$StartIndex + $cut]
    if (!([char]::IsLetterOrDigit($prev) -and [char]::IsLetterOrDigit($next))) {
      break
    }
    $cut -= 1
  }
  return $cut
}

function New-VisualQuery {
  param([string]$Text)
  $rules = @(
    @{ Pattern = 'AI|OpenAI|Codex|\u6A21\u578B|\u667A\u80FD\u4F53|\u4EBA\u5DE5\u667A\u80FD'; Query = "artificial intelligence technology office" },
    @{ Pattern = 'AWS|\u4E91|\u5E73\u53F0|\u90E8\u7F72|\u6570\u636E|\u57FA\u7840\u8BBE\u65BD'; Query = "cloud computing data center servers" },
    @{ Pattern = '\u5B89\u5168|\u5408\u89C4|\u6CBB\u7406|\u6743\u9650|\u98CE\u9669|\u9A8C\u6536|\u7BA1\u7406'; Query = "cybersecurity compliance business meeting" },
    @{ Pattern = '\u91C7\u8D2D|\u9884\u7B97|\u6210\u672C|\u8D39\u7528|\u8D26\u5355|\u8D22\u52A1'; Query = "finance budget planning office" },
    @{ Pattern = '\u4F01\u4E1A|\u516C\u53F8|\u90E8\u95E8|\u56E2\u961F|\u4E1A\u52A1|\u6D41\u7A0B'; Query = "business team workflow office" },
    @{ Pattern = '\u751F\u4EA7\u529B|\u4F7F\u7528|\u5DE5\u5177|\u6548\u7387'; Query = "productivity software office worker" }
  )
  $queries = [System.Collections.Generic.List[string]]::new()
  foreach ($rule in $rules) {
    if ($Text -match $rule.Pattern -and !$queries.Contains($rule.Query)) {
      $queries.Add($rule.Query)
    }
    if ($queries.Count -ge 2) { break }
  }
  if ($queries.Count -gt 0) {
    return ($queries -join " ")
  }
  $clean = ($Text -replace '[^\p{L}\p{Nd}\s-]', ' ') -replace '\s+', ' '
  $words = $clean.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries) |
    Where-Object { $_.Length -ge 2 } |
    Select-Object -First 8
  if (!$words) { return "abstract documentary b-roll" }
  return ($words -join ' ')
}

function Get-AutoKeySegmentScore {
  param([object]$Segment, [int]$TotalSegments)
  $text = [string]$Segment.text
  $score = 0
  foreach ($term in @(
    '\u6838\u5FC3', '\u5173\u952E', '\u91CD\u70B9', '\u771F\u6B63', '\u610F\u5473\u7740',
    '\u4E0D\u662F', '\u800C\u662F', '\u5FC5\u987B', '\u9700\u8981',
    '\u98CE\u9669', '\u6210\u672C', '\u9884\u7B97', '\u8D23\u4EFB', '\u5408\u89C4',
    '\u5B89\u5168', '\u91C7\u8D2D', '\u6CBB\u7406', '\u6743\u9650',
    '\u7BA1\u7406', '\u90E8\u7F72', '\u6D41\u7A0B', '\u4F01\u4E1A',
    '\u957F\u671F', '\u751F\u4EA7\u529B', '\u9A8C\u6536', '\u8D39\u7528', '\u90E8\u95E8'
  )) {
    if ($text -match $term) { $score += 3 }
  }
  foreach ($pattern in @(
    '\u4E0D\u662F.+\u800C\u662F',
    '\u5982\u679C.+\u90A3\u4E48',
    '\u8D8A.+\u8D8A',
    '\u4E0D\u4EC5.+\u8FD8',
    '\u8C01.+\u8C01'
  )) {
    if ($text -match $pattern) { $score += 4 }
  }
  if ($text -match "AI|AWS|OpenAI|Codex|API") { $score += 2 }
  if ($text.Length -ge 35 -and $text.Length -le 120) { $score += 2 }
  if ($Segment.order -ge ([math]::Max(1, $TotalSegments - 1))) { $score += 1 }
  return $score
}

function Set-AutoKeySegments {
  param([array]$Segments, [int]$Count)
  if ($Count -le 0 -or $Segments.Count -eq 0) { return @() }
  if (@($Segments | Where-Object { $_.is_key_segment }).Count -gt 0) { return @() }
  $limit = [math]::Min($Count, [math]::Max(1, [math]::Ceiling($Segments.Count / 3.0)))
  $ranked = @(
    $Segments | ForEach-Object {
      [pscustomobject]@{
        segment = $_
        score = Get-AutoKeySegmentScore -Segment $_ -TotalSegments $Segments.Count
      }
    } | Sort-Object @{ Expression = { $_.score }; Descending = $true }, @{ Expression = { $_.segment.order }; Descending = $false } |
      Select-Object -First $limit
  )
  foreach ($item in $ranked) {
    $item.segment.is_key_segment = $true
    $item.segment.preferred_source = "free-resource"
    $item.segment | Add-Member -MemberType NoteProperty -Name key_segment_reason -Value "auto_score=$($item.score)" -Force
  }
  return @($ranked | ForEach-Object {
    [pscustomobject]@{
      segment_id = $_.segment.id
      score = $_.score
      query = $_.segment.visual_query
      text = $_.segment.text
    }
  })
}

function New-ReferenceSearchQuery {
  param([array]$Segments)
  $sourceSegments = @($Segments | Where-Object { $_.is_key_segment })
  if ($sourceSegments.Count -eq 0) { $sourceSegments = @($Segments | Select-Object -First 3) }
  $words = [System.Collections.Generic.List[string]]::new()
  foreach ($segment in $sourceSegments) {
    $searchText = if ($segment.visual_query -and ([string]$segment.visual_query -match '[A-Za-z]')) {
      [string]$segment.visual_query
    } else {
      [string]$segment.text
    }
    $clean = ($searchText -replace '[^\p{L}\p{Nd}\s-]', ' ') -replace '\s+', ' '
    foreach ($word in $clean.Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)) {
      if ($word.Length -lt 3) { continue }
      if ($words -contains $word) { continue }
      $words.Add($word)
      if ($words.Count -ge 10) { break }
    }
    if ($words.Count -ge 10) { break }
  }
  if ($words.Count -eq 0) { return "documentary b-roll" }
  return ($words -join ' ')
}

function New-LocalTtsAudio {
  param([array]$Segments, [string]$AudioDir, [string]$Voice)
  Add-Type -AssemblyName System.Speech
  $synth = [System.Speech.Synthesis.SpeechSynthesizer]::new()
  if ($Voice) { $synth.SelectVoice($Voice) }
  $synth.Volume = 100
  $synth.Rate = 0
  $items = @()
  foreach ($segment in $Segments) {
    $audio = Join-Path $AudioDir "$($segment.id).wav"
    $synth.SetOutputToWaveFile($audio)
    $synth.Speak($segment.text)
    $synth.SetOutputToNull()
    $items += [pscustomobject]@{
      id = $segment.id
      text_hash = $segment.text_hash
      audio_path = $audio
      duration_seconds = Get-MediaDuration $audio
    }
  }
  $synth.Dispose()
  return $items
}

function New-CommandTtsAudio {
  param(
    [array]$Segments,
    [string]$AudioDir,
    [string]$Voice,
    [string]$Command
  )
  if (!$Command) { throw "TtsCommand is required when TtsProvider is command." }
  $requestDir = Join-Path $AudioDir "tts_requests"
  New-Item -ItemType Directory -Force -Path $requestDir | Out-Null
  $items = @()

  foreach ($segment in $Segments) {
    $audio = Join-Path $AudioDir "$($segment.id).wav"
    $requestPath = Join-Path $requestDir "$($segment.id).json"
    $request = [pscustomobject]@{
      segment_id = $segment.id
      text = $segment.text
      text_hash = $segment.text_hash
      output_audio = $audio
      voice = $Voice
      format = "wav"
    }
    Write-Json $request $requestPath

    if (Test-Path -LiteralPath $Command) {
      $resolvedCommand = (Resolve-Path -LiteralPath $Command).Path
      $ext = [System.IO.Path]::GetExtension($resolvedCommand).ToLowerInvariant()
      if ($ext -eq ".ps1") {
        $commandOutput = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $resolvedCommand -RequestPath $requestPath -OutputPath $audio 2>&1)
      } elseif ($ext -in @(".cmd", ".bat")) {
        $commandOutput = @(& cmd /c "`"$resolvedCommand`" --request `"$requestPath`" --output `"$audio`"" 2>&1)
      } else {
        $commandOutput = @(& $resolvedCommand --request $requestPath --output $audio 2>&1)
      }
    } else {
      $expanded = $Command.Replace("{request}", $requestPath).Replace("{output}", $audio).Replace("{segment_id}", $segment.id)
      $commandOutput = @(& powershell -NoProfile -Command $expanded 2>&1)
    }

    if ($LASTEXITCODE -ne 0) { throw "TTS command failed for $($segment.id) with exit code $LASTEXITCODE. $($commandOutput -join ' ')" }
    if (!(Test-Path -LiteralPath $audio)) { throw "TTS command did not create audio for $($segment.id): $audio" }

    $items += [pscustomobject]@{
      id = $segment.id
      text_hash = $segment.text_hash
      audio_path = $audio
      duration_seconds = Get-MediaDuration $audio
    }
  }

  return $items
}

function New-TtsAudio {
  param(
    [array]$Segments,
    [string]$AudioDir,
    [string]$Voice,
    [string]$Provider,
    [string]$Command
  )
  if ($Provider -eq "local-sapi") {
    return @(New-LocalTtsAudio -Segments $Segments -AudioDir $AudioDir -Voice $Voice)
  }
  if ($Provider -eq "command") {
    return @(New-CommandTtsAudio -Segments $Segments -AudioDir $AudioDir -Voice $Voice -Command $Command)
  }
  throw "Unsupported TTS provider: $Provider"
}

function Get-MediaDuration {
  param([string]$Path)
  $ffprobe = Get-ToolPath "ffprobe"
  if (!$ffprobe) { throw "ffprobe not found." }
  $raw = & $ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$Path"
  if ($LASTEXITCODE -ne 0 -or !$raw) { throw "Could not read duration: $Path" }
  return [double]::Parse($raw.Trim(), [Globalization.CultureInfo]::InvariantCulture)
}

function Get-FileSha256 {
  param([string]$Path)
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Read-AsrTranscript {
  param([string]$Path)
  if (!$Path) { return $null }
  if (!(Test-Path -LiteralPath $Path)) { throw "TranscriptPath does not exist: $Path" }
  return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Invoke-MockAsr {
  param([string]$AudioPathValue, [string]$OutputPath)
  $duration = Get-MediaDuration $AudioPathValue
  $mid = [math]::Max(0.5, $duration / 2.0)
  $result = [pscustomobject]@{
    provider = "mock"
    audio_path = $AudioPathValue
    language = "en"
    text = "This is an audio only script generated by the mock ASR module. This key segment should use authorized B-roll assets."
    segments = @(
      [pscustomobject]@{
        start_seconds = 0.0
        end_seconds = [math]::Round($mid, 3)
        text = "This is an audio only script generated by the mock ASR module."
      },
      [pscustomobject]@{
        start_seconds = [math]::Round($mid, 3)
        end_seconds = [math]::Round($duration, 3)
        text = "This key segment should use authorized B-roll assets."
      }
    )
  }
  Write-Json $result $OutputPath 8
  return $result
}

function Invoke-CommandAsr {
  param(
    [string]$AudioPathValue,
    [string]$OutputPath,
    [string]$Language,
    [string]$Command
  )
  if (!$Command) { throw "AsrCommand is required when AsrProvider is command." }
  $requestPath = Join-Path (Split-Path -Parent $OutputPath) "asr-request.json"
  $request = [pscustomobject]@{
    audio_path = $AudioPathValue
    output_json = $OutputPath
    language = $Language
    format = "json"
  }
  Write-Json $request $requestPath 8

  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    if (Test-Path -LiteralPath $Command) {
      $resolvedCommand = (Resolve-Path -LiteralPath $Command).Path
      $ext = [System.IO.Path]::GetExtension($resolvedCommand).ToLowerInvariant()
      if ($ext -eq ".ps1") {
        $commandOutput = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $resolvedCommand -RequestPath $requestPath -OutputPath $OutputPath 2>&1)
      } elseif ($ext -in @(".cmd", ".bat")) {
        $commandOutput = @(& cmd /c "`"$resolvedCommand`" --request `"$requestPath`" --output `"$OutputPath`"" 2>&1)
      } else {
        $commandOutput = @(& $resolvedCommand --request $requestPath --output $OutputPath 2>&1)
      }
    } else {
      $expanded = $Command.Replace("{request}", $requestPath).Replace("{output}", $OutputPath).Replace("{audio}", $AudioPathValue)
      $commandOutput = @(& powershell -NoProfile -Command $expanded 2>&1)
    }
    $exitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }

  if ($exitCode -ne 0) { throw "ASR command failed with exit code $exitCode. $($commandOutput -join ' ')" }
  if (!(Test-Path -LiteralPath $OutputPath)) { throw "ASR command did not create transcript: $OutputPath" }
  return Read-AsrTranscript -Path $OutputPath
}

function Invoke-FasterWhisperAsr {
  param([string]$AudioPathValue, [string]$OutputPath, [string]$Language)
  $script = Join-Path $PSScriptRoot "asr-faster-whisper.py"
  if (!(Test-Path -LiteralPath $script)) { throw "Bundled faster-whisper adapter missing: $script" }
  $python = Get-ToolPath "python"
  if (!$python) { $python = Get-ToolPath "python3" }
  if (!$python) { throw "python is required for AsrProvider=faster-whisper." }
  $args = @($script, "--audio", $AudioPathValue, "--output", $OutputPath)
  if ($Language) { $args += @("--language", $Language) }
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $commandOutput = @(& $python @args 2>&1)
    $exitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  if ($exitCode -ne 0) {
    throw "faster-whisper ASR failed with exit code $exitCode. Install faster-whisper or use AsrProvider=command. $($commandOutput -join ' ')"
  }
  if (!(Test-Path -LiteralPath $OutputPath)) { throw "faster-whisper did not create transcript: $OutputPath" }
  return Read-AsrTranscript -Path $OutputPath
}

function Invoke-Asr {
  param(
    [string]$AudioPathValue,
    [string]$OutputPath,
    [string]$Provider,
    [string]$Command,
    [string]$Language,
    [string]$ExistingTranscriptPath
  )
  if ($ExistingTranscriptPath) {
    $transcript = Read-AsrTranscript -Path $ExistingTranscriptPath
    Write-Json $transcript $OutputPath 12
    return $transcript
  }
  if ($Provider -eq "none") { $Provider = "faster-whisper" }
  if ($Provider -eq "mock") { return Invoke-MockAsr -AudioPathValue $AudioPathValue -OutputPath $OutputPath }
  if ($Provider -eq "command") { return Invoke-CommandAsr -AudioPathValue $AudioPathValue -OutputPath $OutputPath -Language $Language -Command $Command }
  if ($Provider -eq "faster-whisper") { return Invoke-FasterWhisperAsr -AudioPathValue $AudioPathValue -OutputPath $OutputPath -Language $Language }
  throw "Unsupported ASR provider: $Provider"
}

function Convert-AsrTranscriptToSegments {
  param(
    [object]$Transcript,
    [double]$AudioDuration,
    [int]$MaxChars,
    [string[]]$Keywords
  )
  $rawSegments = @($Transcript.segments)
  if ($rawSegments.Count -eq 0 -and $Transcript.text) {
    $rawSegments = @([pscustomobject]@{ start_seconds = 0.0; end_seconds = $AudioDuration; text = [string]$Transcript.text })
  }
  if ($rawSegments.Count -eq 0) { throw "ASR transcript contains no segments." }

  $segments = @()
  $index = 1
  for ($rawIndex = 0; $rawIndex -lt $rawSegments.Count; $rawIndex++) {
    $raw = $rawSegments[$rawIndex]
    $text = ([regex]::Replace([string]$raw.text, "\s+", " ")).Trim()
    if (!$text) { continue }

    $start = if ($null -ne $raw.start_seconds) { [double]$raw.start_seconds } elseif ($null -ne $raw.start) { [double]$raw.start } else { 0.0 }
    $end = if ($null -ne $raw.end_seconds) { [double]$raw.end_seconds } elseif ($null -ne $raw.end) { [double]$raw.end } else { $AudioDuration }
    if ($rawIndex -eq 0 -and $start -gt 0.0) { $start = 0.0 }
    if ($rawIndex -lt ($rawSegments.Count - 1)) {
      $next = $rawSegments[$rawIndex + 1]
      $nextStart = if ($null -ne $next.start_seconds) { [double]$next.start_seconds } elseif ($null -ne $next.start) { [double]$next.start } else { $end }
      if ($nextStart -gt $end) { $end = $nextStart }
    } else {
      if ($AudioDuration -gt $end) { $end = $AudioDuration }
    }
    $start = [math]::Max(0.0, [math]::Min($start, $AudioDuration))
    $end = [math]::Max($start + 0.1, [math]::Min($end, $AudioDuration))

    $parts = @(Split-IntoSegments -Text $text -MaxChars $MaxChars -Keywords $Keywords)
    if ($parts.Count -eq 0) { continue }
    $weights = @($parts | ForEach-Object { [math]::Max(1, (Get-SubtitleTextLength $_.text)) })
    $totalWeight = [double](($weights | Measure-Object -Sum).Sum)
    if ($totalWeight -le 0) { $totalWeight = [double]$parts.Count }

    $cursor = $start
    for ($partIndex = 0; $partIndex -lt $parts.Count; $partIndex++) {
      if ($partIndex -eq ($parts.Count - 1)) {
        $partEnd = $end
      } else {
        $partEnd = $cursor + (($end - $start) * ([double]$weights[$partIndex] / $totalWeight))
      }
      $id = "seg_{0:000}" -f $index
      $partText = $parts[$partIndex].text
      $segments += [pscustomobject]@{
        id = $id
        order = $index
        text = $partText
        text_hash = Get-StringSha256 $partText
        is_key_segment = [bool]$parts[$partIndex].is_key_segment
        visual_query = New-VisualQuery $partText
        preferred_source = $(if ($parts[$partIndex].is_key_segment) { "free-resource" } else { "reference_video" })
        asr_start_seconds = [math]::Round($cursor, 3)
        asr_end_seconds = [math]::Round($partEnd, 3)
      }
      $index += 1
      $cursor = $partEnd
    }
  }
  return $segments
}

function New-AudioItemsFromSourceAudio {
  param([array]$Segments, [string]$SourceAudioPath, [string]$AudioDir)
  $ffmpeg = Get-ToolPath "ffmpeg"
  if (!$ffmpeg) { throw "ffmpeg not found." }
  $items = @()
  foreach ($segment in $Segments) {
    $audio = Join-Path $AudioDir "$($segment.id).wav"
    $start = [double]$segment.asr_start_seconds
    $end = [double]$segment.asr_end_seconds
    $duration = [math]::Max(0.1, $end - $start)
    & $ffmpeg -y -hide_banner -loglevel error -ss $start -t $duration -i "$SourceAudioPath" -vn -ac 1 -ar 22050 "$audio" | Out-Null
    if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $audio)) { throw "Failed to cut ASR audio segment $($segment.id)." }
    $items += [pscustomobject]@{
      id = $segment.id
      text_hash = $segment.text_hash
      audio_path = $audio
      duration_seconds = Get-MediaDuration $audio
    }
  }
  return $items
}

function Join-AudioFiles {
  param([array]$AudioItems, [string]$ProjectRoot, [string]$OutputPath)
  $ffmpeg = Get-ToolPath "ffmpeg"
  $list = Join-Path $ProjectRoot "audio\concat_audio.txt"
  $lines = foreach ($item in $AudioItems) {
    "file '$($item.audio_path.Replace("'", "''"))'"
  }
  Write-Utf8File $list ($lines -join "`n")
  & $ffmpeg -y -hide_banner -f concat -safe 0 -i "$list" -c copy "$OutputPath" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Failed to concatenate narration audio." }
}

function Write-Srt {
  param([array]$Segments, [array]$AudioItems, [string]$Path)
  $cursor = 0.0
  $blocks = @()
  $cueIndex = 1
  for ($i = 0; $i -lt $Segments.Count; $i++) {
    $duration = [double]$AudioItems[$i].duration_seconds
    $segmentStart = $cursor
    $segmentEnd = $cursor + $duration
    $chunks = @(Split-SubtitleText -Text $Segments[$i].text)
    if ($chunks.Count -eq 0) {
      $cursor = $segmentEnd
      continue
    }

    $weights = @($chunks | ForEach-Object { [math]::Max(1, (Get-SubtitleTextLength $_)) })
    $totalWeight = [double](($weights | Measure-Object -Sum).Sum)
    if ($totalWeight -le 0) { $totalWeight = [double]$chunks.Count }

    $chunkStart = $segmentStart
    for ($j = 0; $j -lt $chunks.Count; $j++) {
      if ($j -eq ($chunks.Count - 1)) {
        $chunkEnd = $segmentEnd
      } else {
        $chunkEnd = $chunkStart + ($duration * ([double]$weights[$j] / $totalWeight))
      }
      $blocks += @(
        "$cueIndex",
        "$(Format-SrtTime $chunkStart) --> $(Format-SrtTime $chunkEnd)",
        "$($chunks[$j])",
        ""
      )
      $cueIndex += 1
      $chunkStart = $chunkEnd
    }
    $cursor = $segmentEnd
  }
  Write-Utf8File $Path ($blocks -join "`r`n")
}

function Get-YtDlpFailureCategory {
  param([string]$Text)
  if ($Text -match "Could not copy Chrome cookie database") { return "cookie_copy_failed" }
  if ($Text -match "Failed to decrypt with DPAPI") { return "dpapi_decrypt_failed" }
  if ($Text -match "could not find .*cookies database" -or $Text -match "could not find .*cookie database") { return "browser_cookies_missing" }
  if ($Text -match "Sign in to confirm.*not a bot" -or $Text -match "cookies.*authentication") { return "auth_required" }
  if ($Text -match "Video unavailable") { return "video_unavailable" }
  if ($Text -match "HTTP Error 429" -or $Text -match "Too Many Requests") { return "rate_limited" }
  if ($Text -match "Unsupported URL") { return "unsupported_url" }
  if ($Text -match "Unable to download webpage" -or $Text -match "timed out" -or $Text -match "Temporary failure") { return "network_error" }
  return "unknown"
}

function Get-YtDlpFailureHint {
  param([string]$Category)
  if ($Category -eq "cookie_copy_failed") { return "yt-dlp could not copy the Chromium cookie database. Close Edge/Chrome and retry, or export cookies.txt and pass -YtDlpCookiesPath." }
  if ($Category -eq "dpapi_decrypt_failed") { return "yt-dlp found Chrome cookies but Windows DPAPI decryption failed. Export cookies.txt from the logged-in browser, try another Chrome profile, or try another browser source." }
  if ($Category -eq "browser_cookies_missing") { return "No browser cookie database was found for this browser. Log in to YouTube in that browser, or export cookies.txt and pass -YtDlpCookiesPath." }
  if ($Category -eq "auth_required") { return "YouTube requires login or bot verification. Provide -YtDlpCookiesPath with a cookies.txt export, or -YtDlpCookiesFromBrowser with an unlocked browser profile." }
  if ($Category -eq "video_unavailable") { return "The reference URL is unavailable. Use another URL or provide a local reference video." }
  if ($Category -eq "rate_limited") { return "YouTube is rate limiting this environment. Wait, change network, or provide cookies." }
  if ($Category -eq "unsupported_url") { return "yt-dlp does not support this URL. Use a YouTube URL, ytsearch query, or local reference video." }
  if ($Category -eq "network_error") { return "Network access failed while yt-dlp was contacting the site. Retry or provide a local reference video." }
  return "Inspect the yt-dlp output log and retry with cookies or a local reference video."
}

function Download-ReferenceVideos {
  param(
    [string[]]$Urls,
    [string]$DownloadDir,
    [string]$CookiesFromBrowser = "",
    [string]$CookiesPath = ""
  )
  $ytDlp = Get-ToolPath "yt-dlp"
  if (!$ytDlp -and $Urls.Count -gt 0) { throw "yt-dlp not found. Downloaded fallback path expected at $env:USERPROFILE\.local\bin\yt-dlp.exe" }
  $downloaded = @()
  $results = @()
  $manifestPath = Join-Path $DownloadDir "yt-dlp-results.json"
  foreach ($url in $Urls) {
    $template = Join-Path $DownloadDir "%(title).180B [%(id)s].%(ext)s"
    $ytArgs = @("-f", "bv*[ext=mp4]/bv*/b[ext=mp4]/b", "-o", $template)
    if ($CookiesPath) {
      $ytArgs += @("--cookies", $CookiesPath)
    } elseif ($CookiesFromBrowser) {
      $ytArgs += @("--cookies-from-browser", $CookiesFromBrowser)
    }
    $ytArgs += $url
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
      $ytOutput = @(& $ytDlp @ytArgs 2>&1)
      $ytExitCode = $LASTEXITCODE
    } finally {
      $ErrorActionPreference = $previousErrorActionPreference
    }
    $outputText = ($ytOutput | ForEach-Object { "$_" }) -join "`n"
    if ($ytExitCode -ne 0) {
      $category = Get-YtDlpFailureCategory $outputText
      $hint = Get-YtDlpFailureHint $category
      $results += [pscustomobject]@{
        input = $url
        status = "failed"
        exit_code = $ytExitCode
        category = $category
        hint = $hint
        output = $outputText
      }
      Write-Json ([pscustomobject]@{ yt_dlp = $ytDlp; cookies_from_browser = $CookiesFromBrowser; cookies_path = $CookiesPath; results = $results }) $manifestPath 8
      throw "yt-dlp failed for $url. category=$category. $hint"
    }
    $after = Get-ChildItem -LiteralPath $DownloadDir -File |
      Where-Object { $_.Extension -in ".mp4", ".mkv", ".webm", ".mov" } |
      Sort-Object LastWriteTime -Descending
    $newest = $after | Select-Object -First 1
    if ($newest) {
      $downloaded += $newest.FullName
      $results += [pscustomobject]@{
        input = $url
        status = "completed"
        exit_code = $ytExitCode
        output_file = $newest.FullName
        output = $outputText
      }
    } else {
      $results += [pscustomobject]@{
        input = $url
        status = "completed-no-file"
        exit_code = $ytExitCode
        output = $outputText
      }
    }
  }
  if ($results.Count -gt 0) {
    Write-Json ([pscustomobject]@{ yt_dlp = $ytDlp; cookies_from_browser = $CookiesFromBrowser; cookies_path = $CookiesPath; results = $results }) $manifestPath 8
  }
  return $downloaded
}

function New-MutedVideo {
  param([string]$InputPath, [string]$OutputPath)
  $ffmpeg = Get-ToolPath "ffmpeg"
  & $ffmpeg -y -hide_banner -i "$InputPath" -an -c:v copy "$OutputPath" | Out-Null
  if ($LASTEXITCODE -ne 0) {
    & $ffmpeg -y -hide_banner -i "$InputPath" -an -c:v libx264 -preset veryfast -crf 20 "$OutputPath" | Out-Null
  }
  if ($LASTEXITCODE -ne 0) { throw "Failed to create muted video: $InputPath" }
}

function Split-ReferenceVideo {
  param([string]$InputPath, [string]$OutputDir, [double]$Threshold, [double]$MinDuration, [double]$PreferredMaxDuration, [double]$MaxDuration)
  $ffmpeg = Get-ToolPath "ffmpeg"
  $ffprobe = Get-ToolPath "ffprobe"
  New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
  if ($MinDuration -le 0) { $MinDuration = 5 }
  if ($PreferredMaxDuration -le 0) { $PreferredMaxDuration = 8 }
  if ($MaxDuration -le 0) { $MaxDuration = 15 }
  $hardMaxDuration = [math]::Min([math]::Max($MaxDuration, $MinDuration), 15.0)
  $preferredMaxDuration = [math]::Min([math]::Max($PreferredMaxDuration, $MinDuration), $hardMaxDuration)
  $durationRaw = & $ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$InputPath"
  $duration = [double]::Parse($durationRaw.Trim(), [Globalization.CultureInfo]::InvariantCulture)
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $detect = & $ffmpeg -hide_banner -i "$InputPath" -vf "select='gt(scene,$Threshold)',showinfo" -f null - 2>&1
  $ErrorActionPreference = $previousErrorActionPreference
  if ($LASTEXITCODE -ne 0) { throw "Scene detection failed: $InputPath" }
  $sceneTimes = @()
  foreach ($line in $detect) {
    if ($line -match "pts_time:([0-9]+(?:\.[0-9]+)?)") {
      $sceneTimes += [double]::Parse($Matches[1], [Globalization.CultureInfo]::InvariantCulture)
    }
  }
  $sceneTimes = $sceneTimes | Where-Object { $_ -gt 0.5 -and $_ -lt ($duration - 0.5) } | Sort-Object -Unique
  $segments = New-Object System.Collections.Generic.List[object]

  function Add-ReferenceSceneSegment {
    param(
      [System.Collections.Generic.List[object]]$Target,
      [double]$Start,
      [double]$End,
      [double]$MinimumDuration,
      [double]$PreferredMaximumDuration,
      [double]$HardMaximumDuration
    )
    $length = $End - $Start
    if ($length -lt $MinimumDuration) { return }
    if ($length -le $HardMaximumDuration) {
      $Target.Add([pscustomobject]@{ Start = $Start; End = $End })
      return
    }

    $cursor = $Start
    while (($End - $cursor) -gt $HardMaximumDuration) {
      $chunkEnd = [math]::Min($cursor + $PreferredMaximumDuration, $End)
      if (($End - $chunkEnd) -gt 0 -and ($End - $chunkEnd) -lt $MinimumDuration) {
        $chunkEnd = [math]::Min($cursor + $HardMaximumDuration, $End)
      }
      $Target.Add([pscustomobject]@{ Start = $cursor; End = $chunkEnd })
      $cursor = $chunkEnd
    }

    if (($End - $cursor) -ge $MinimumDuration) {
      $Target.Add([pscustomobject]@{ Start = $cursor; End = $End })
    } elseif ($Target.Count -gt 0) {
      $last = $Target[$Target.Count - 1]
      if (($End - [double]$last.Start) -le $HardMaximumDuration) {
        $last.End = $End
      }
    }
  }

  function Test-ReferenceClipOutput {
    param([string]$Path, [double]$ExpectedDuration)
    if (!(Test-Path -LiteralPath $Path)) { return $false }
    try {
      $actualDuration = Get-MediaDuration $Path
      $sizeBytes = (Get-Item -LiteralPath $Path).Length
      if ($actualDuration -lt ([math]::Min(0.5, $ExpectedDuration * 0.5))) { return $false }
      if ($sizeBytes -lt 50000) { return $false }
      return $true
    } catch {
      return $false
    }
  }

  $start = 0.0
  foreach ($cut in (@($sceneTimes) + @($duration))) {
    if ($null -eq $cut) { continue }
    if (($cut - $start) -lt $MinDuration -and $cut -lt $duration) { continue }
    Add-ReferenceSceneSegment -Target $segments -Start $start -End $cut -MinimumDuration $MinDuration -PreferredMaximumDuration $preferredMaxDuration -HardMaximumDuration $hardMaxDuration
    $start = $cut
  }
  $clips = @()
  $idx = 1
  foreach ($seg in $segments) {
    $out = Join-Path $OutputDir ("clip_{0:000}_{1:000000}-{2:000000}.mp4" -f $idx, [math]::Floor($seg.Start), [math]::Floor($seg.End))
    $expectedDuration = [double]$seg.End - [double]$seg.Start
    & $ffmpeg -y -hide_banner -ss $seg.Start -to $seg.End -i "$InputPath" -c copy "$out" | Out-Null
    $clipOk = ($LASTEXITCODE -eq 0 -and (Test-ReferenceClipOutput -Path $out -ExpectedDuration $expectedDuration))
    if (!$clipOk) {
      Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue
      & $ffmpeg -y -hide_banner -ss $seg.Start -to $seg.End -i "$InputPath" -c:v libx264 -preset veryfast -crf 22 -an "$out" | Out-Null
      $clipOk = ($LASTEXITCODE -eq 0 -and (Test-ReferenceClipOutput -Path $out -ExpectedDuration $expectedDuration))
    }
    if ($clipOk) { $clips += $out }
    $idx += 1
  }
  return $clips
}

function Invoke-FreeResourceForKeySegments {
  param(
    [array]$Segments,
    [string]$ProjectRoot,
    [string]$FreeRoot,
    [string]$Command,
    [string]$AspectRatioValue,
    [switch]$Require
  )
  if (!$Command) { return @() }
  $results = @()
  foreach ($segment in ($Segments | Where-Object { $_.is_key_segment })) {
    $segmentDir = Join-Path $FreeRoot $segment.id
    New-Item -ItemType Directory -Force -Path $segmentDir | Out-Null
    $existing = @(Get-ChildItem -LiteralPath $segmentDir -File -Recurse -ErrorAction SilentlyContinue |
      Where-Object { $_.Extension -in ".mp4", ".mov", ".mkv", ".webm" })
    if ($existing.Count -gt 0) {
      $results += [pscustomobject]@{ segment_id = $segment.id; status = "skipped-existing"; output_dir = $segmentDir }
      continue
    }

    $requestPath = Join-Path $segmentDir "free-resource-request.json"
    $request = [pscustomobject]@{
      segment_id = $segment.id
      text = $segment.text
      query = $segment.visual_query
      media_type = "video"
      aspect_ratio = $AspectRatioValue
      output_dir = $segmentDir
      source_priority = @("pexels", "pixabay")
    }
    Write-Json $request $requestPath

    try {
      if (Test-Path -LiteralPath $Command) {
        $resolvedCommand = (Resolve-Path -LiteralPath $Command).Path
        $ext = [System.IO.Path]::GetExtension($resolvedCommand).ToLowerInvariant()
        if ($ext -eq ".ps1") {
          $commandOutput = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $resolvedCommand -RequestPath $requestPath -OutputDir $segmentDir 2>&1)
        } elseif ($ext -in @(".cmd", ".bat")) {
          $commandOutput = @(& cmd /c "`"$resolvedCommand`" --request `"$requestPath`" --output-dir `"$segmentDir`"" 2>&1)
        } else {
          $commandOutput = @(& $resolvedCommand --request $requestPath --output-dir $segmentDir 2>&1)
        }
      } else {
        $expanded = $Command.Replace("{request}", $requestPath).Replace("{output}", $segmentDir).Replace("{segment_id}", $segment.id)
        $commandOutput = @(& powershell -NoProfile -Command $expanded 2>&1)
      }
      if ($LASTEXITCODE -ne 0) {
        throw "free-resource command exited with code $LASTEXITCODE. $($commandOutput -join ' ')"
      }
      $results += [pscustomobject]@{ segment_id = $segment.id; status = "completed"; output_dir = $segmentDir; request = $requestPath }
    } catch {
      $results += [pscustomobject]@{ segment_id = $segment.id; status = "failed"; error = $_.Exception.Message; output_dir = $segmentDir; request = $requestPath }
      if ($Require) { throw "free-resource failed for $($segment.id): $($_.Exception.Message)" }
      Write-Warning "free-resource failed for $($segment.id), falling back to reference/placeholder visuals: $($_.Exception.Message)"
    }
  }
  return $results
}

function New-PlaceholderVideo {
  param([string]$OutputPath, [double]$Duration, [int]$Width, [int]$Height, [int]$Index)
  $ffmpeg = Get-ToolPath "ffmpeg"
  $colors = @("0x1f4e79", "0x5b3f8c", "0x2f6f4e", "0x7a4b1f", "0x623b5a", "0x3f5f7f")
  $color = $colors[($Index - 1) % $colors.Count]
  & $ffmpeg -y -hide_banner -f lavfi -i "color=c=${color}:s=${Width}x${Height}:d=$Duration" -an -pix_fmt yuv420p "$OutputPath" | Out-Null
  if ($LASTEXITCODE -ne 0) {
    & $ffmpeg -y -hide_banner -f lavfi -i "testsrc2=s=${Width}x${Height}:d=$Duration" -an -pix_fmt yuv420p "$OutputPath" | Out-Null
  }
  if ($LASTEXITCODE -ne 0) { throw "Failed to create placeholder video." }
}

function Get-VideoFrameMeanBrightness {
  param([string]$Path)
  $ffmpeg = Get-ToolPath "ffmpeg"
  if (!$ffmpeg) { return $null }

  $tempFrame = Join-Path ([System.IO.Path]::GetTempPath()) ("script-broll-brightness-{0}.bmp" -f ([guid]::NewGuid().ToString("N")))
  try {
    & $ffmpeg -y -hide_banner -loglevel error -ss 1 -i "$Path" -frames:v 1 -vf "scale=64:36" "$tempFrame" | Out-Null
    if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $tempFrame)) { return $null }

    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    $bitmap = [System.Drawing.Bitmap]::FromFile($tempFrame)
    try {
      $total = 0.0
      $count = 0
      for ($x = 0; $x -lt $bitmap.Width; $x++) {
        for ($y = 0; $y -lt $bitmap.Height; $y++) {
          $pixel = $bitmap.GetPixel($x, $y)
          $total += (($pixel.R + $pixel.G + $pixel.B) / 3.0)
          $count += 1
        }
      }
      if ($count -le 0) { return $null }
      return ($total / $count)
    } finally {
      $bitmap.Dispose()
    }
  } catch {
    return $null
  } finally {
    Remove-Item -LiteralPath $tempFrame -Force -ErrorAction SilentlyContinue
  }
}

function Get-UsableReferenceClips {
  param([string[]]$ReferenceClips)
  $usable = @()
  foreach ($clip in $ReferenceClips) {
    $brightness = Get-VideoFrameMeanBrightness -Path $clip
    if ($null -eq $brightness -or $brightness -ge 18.0) {
      $usable += $clip
    }
  }
  if ($usable.Count -eq 0) { return $ReferenceClips }
  return $usable
}

function Get-ShuffledReferenceClips {
  param([string[]]$ReferenceClips)
  $clips = @($ReferenceClips)
  if ($clips.Count -le 1) { return $clips }
  $items = @()
  for ($i = 0; $i -lt $clips.Count; $i++) {
    $path = [string]$clips[$i]
    $key = Get-StringSha256 ("reference-shuffle-v1|$i|$([System.IO.Path]::GetFileName($path))|$path")
    $items += [pscustomobject]@{
      key = $key
      original_index = $i
      path = $path
    }
  }
  $shuffled = @($items | Sort-Object key, original_index | ForEach-Object { $_.path })
  $sameOrder = $true
  for ($i = 0; $i -lt $clips.Count; $i++) {
    if ($shuffled[$i] -ne $clips[$i]) {
      $sameOrder = $false
      break
    }
  }
  if ($sameOrder) {
    $shuffled = @($shuffled[1..($shuffled.Count - 1)] + $shuffled[0])
  }
  return $shuffled
}

function Select-VisualAssets {
  param([array]$Segments, [array]$AudioItems, [string[]]$ReferenceClips, [string]$FreeRoot, [string]$SelectedDir, [int]$Width, [int]$Height)
  $assetPlan = @()
  $referenceIndex = 0
  $usableReferenceClips = @(Get-ShuffledReferenceClips -ReferenceClips @(Get-UsableReferenceClips -ReferenceClips $ReferenceClips))
  for ($i = 0; $i -lt $Segments.Count; $i++) {
    $seg = $Segments[$i]
    $duration = [double]$AudioItems[$i].duration_seconds
    $selected = $null
    $sourceType = "placeholder"
    $candidates = @()
    if ($seg.is_key_segment -and $FreeRoot) {
      $freeSegDir = Join-Path $FreeRoot $seg.id
      if (Test-Path -LiteralPath $freeSegDir) {
        $freeVideos = @(Get-ChildItem -LiteralPath $freeSegDir -File -Recurse |
          Where-Object { $_.Extension -in ".mp4", ".mov", ".mkv", ".webm" } |
          Select-Object -ExpandProperty FullName)
        if ($freeVideos) {
          $selected = $freeVideos[0]
          $sourceType = "free-resource"
          $candidates = $freeVideos
        }
      }
    }
    if (!$selected -and $usableReferenceClips.Count -gt 0) {
      $selected = $usableReferenceClips[$referenceIndex % $usableReferenceClips.Count]
      $sourceType = "reference_video"
      $candidates = @($selected)
      $referenceIndex += 1
    }
    if (!$selected) {
      $selected = Join-Path $SelectedDir "$($seg.id)_placeholder.mp4"
      New-PlaceholderVideo -OutputPath $selected -Duration $duration -Width $Width -Height $Height -Index ($i + 1)
      $candidates = @($selected)
    }
    $prepared = Join-Path $SelectedDir "$($seg.id).mp4"
    Prepare-VisualForSegment -InputPath $selected -OutputPath $prepared -Duration $duration -Width $Width -Height $Height
    $assetPlan += [pscustomobject]@{
      segment_id = $seg.id
      source_type = $sourceType
      query = $seg.visual_query
      selected_asset = $prepared
      candidate_assets = $candidates
      selection_policy = $(if ($sourceType -eq "reference_video") { "deterministic-shuffled-reference-order" } else { "" })
      duration_seconds = [math]::Round($duration, 3)
    }
  }
  return $assetPlan
}

function Prepare-VisualForSegment {
  param([string]$InputPath, [string]$OutputPath, [double]$Duration, [int]$Width, [int]$Height)
  $ffmpeg = Get-ToolPath "ffmpeg"
  & $ffmpeg -y -hide_banner -stream_loop -1 -i "$InputPath" -t $Duration -vf "scale=${Width}:${Height}:force_original_aspect_ratio=increase,crop=${Width}:${Height},fps=30" -an -c:v libx264 -preset veryfast -crf 22 -pix_fmt yuv420p "$OutputPath" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Failed to prepare visual asset: $InputPath" }
}

function Render-Segments {
  param([array]$Segments, [array]$AudioItems, [array]$AssetPlan, [string]$ProjectRoot, [string]$IntermediateDir)
  $ffmpeg = Get-ToolPath "ffmpeg"
  $outputs = @()
  for ($i = 0; $i -lt $Segments.Count; $i++) {
    $id = $Segments[$i].id
    $visual = $AssetPlan[$i].selected_asset
    $audio = $AudioItems[$i].audio_path
    $duration = [double]$AudioItems[$i].duration_seconds
    $out = Join-Path $IntermediateDir "$id.mp4"
    & $ffmpeg -y -hide_banner -i "$visual" -i "$audio" -t $duration -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -shortest "$out" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to render segment: $id" }
    $outputs += $out
  }
  return $outputs
}

function Concat-Videos {
  param([string[]]$Videos, [string]$ProjectRoot, [string]$OutputPath)
  $ffmpeg = Get-ToolPath "ffmpeg"
  $list = Join-Path $ProjectRoot "render\concat_inputs.txt"
  $lines = foreach ($video in $Videos) { "file '$($video.Replace("'", "''"))'" }
  Write-Utf8File $list ($lines -join "`n")
  & $ffmpeg -y -hide_banner -f concat -safe 0 -i "$list" -c copy "$OutputPath" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Failed to concatenate videos." }
}

function Add-SoftSubtitle {
  param([string]$InputVideo, [string]$SrtPath, [string]$OutputVideo)
  $ffmpeg = Get-ToolPath "ffmpeg"
  & $ffmpeg -y -hide_banner -i "$InputVideo" -i "$SrtPath" -c:v copy -c:a copy -c:s mov_text "$OutputVideo" | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Copy-Item -LiteralPath $InputVideo -Destination $OutputVideo -Force
  }
}

function Add-BurnedSubtitle {
  param([string]$InputVideo, [string]$SrtPath, [string]$OutputVideo)
  $ffmpeg = Get-ToolPath "ffmpeg"
  $filterPath = ([System.IO.Path]::GetFullPath($SrtPath)).Replace('\', '/').Replace(':', '\:')
  & $ffmpeg -y -hide_banner -i "$InputVideo" -vf "subtitles='$filterPath'" -c:a copy "$OutputVideo" | Out-Null
  return ($LASTEXITCODE -eq 0)
}

$ffmpegPath = Get-ToolPath "ffmpeg"
$ffprobePath = Get-ToolPath "ffprobe"
if (!$ffmpegPath -or !$ffprobePath) { throw "ffmpeg and ffprobe are required." }
if ($ReferenceSearchLimit -lt 1) { throw "ReferenceSearchLimit must be 1 or greater." }
$cwdPath = (Resolve-Path -LiteralPath ".").Path
Import-DotEnvKeys -Paths @(
  (Join-Path $cwdPath ".env"),
  (Join-Path $env:USERPROFILE ".codex\.env"),
  (Join-Path $env:USERPROFILE ".agents\.env")
) -AllowedKeys @("FREE_RESOURCE_COMMAND", "FREE_RESOURCE_ROOT", "FREE_RESOURCE_SKILL_ROOT", "FREE_RESOURCE_CONFIG_PATH", "PEXELS_API_KEY", "PIXABAY_API_KEY", "YTDLP_COOKIES_FROM_BROWSER", "YTDLP_COOKIES_PATH")
if (!$FreeResourceCommand -and $env:FREE_RESOURCE_COMMAND) {
  $FreeResourceCommand = $env:FREE_RESOURCE_COMMAND
}
if (!$FreeResourceRoot -and $env:FREE_RESOURCE_ROOT) {
  $FreeResourceRoot = $env:FREE_RESOURCE_ROOT
}
if (!$YtDlpCookiesFromBrowser -and $env:YTDLP_COOKIES_FROM_BROWSER) {
  $YtDlpCookiesFromBrowser = $env:YTDLP_COOKIES_FROM_BROWSER
}
if (!$YtDlpCookiesPath -and $env:YTDLP_COOKIES_PATH) {
  $YtDlpCookiesPath = $env:YTDLP_COOKIES_PATH
}

$bundledFreeResourceAdapter = Join-Path $PSScriptRoot "free-resource-api-adapter.ps1"
if ($FreeResourceCommand -and (Test-Path -LiteralPath $FreeResourceCommand -PathType Container)) {
  $freeResourceSkillRoot = (Resolve-Path -LiteralPath $FreeResourceCommand).Path
  [Environment]::SetEnvironmentVariable("FREE_RESOURCE_SKILL_ROOT", $freeResourceSkillRoot, "Process")
  $freeResourceConfigPath = Join-Path $freeResourceSkillRoot "config.json"
  if ((Test-Path -LiteralPath $freeResourceConfigPath) -and !$env:FREE_RESOURCE_CONFIG_PATH) {
    [Environment]::SetEnvironmentVariable("FREE_RESOURCE_CONFIG_PATH", $freeResourceConfigPath, "Process")
  }
  $FreeResourceCommand = $bundledFreeResourceAdapter
}
if (!$FreeResourceCommand -and (Test-Path -LiteralPath $bundledFreeResourceAdapter) -and ($env:PEXELS_API_KEY -or $env:PIXABAY_API_KEY -or $env:FREE_RESOURCE_SKILL_ROOT -or $env:FREE_RESOURCE_CONFIG_PATH)) {
  $FreeResourceCommand = $bundledFreeResourceAdapter
}

if (!$DocumentPath -and !$AudioPath) { throw "DocumentPath or AudioPath is required." }
if ($DocumentPath -and $AudioPath) { throw "Provide either DocumentPath or AudioPath, not both." }

$sourceMode = if ($AudioPath) { "audio-asr" } else { "document" }
$docResolved = $null
$audioResolved = $null
$sourceAudioHash = ""
if ($sourceMode -eq "document") {
  $docResolved = Resolve-Path -LiteralPath $DocumentPath
  if (!$ProjectId) {
    $ProjectId = "$(New-Slug ([System.IO.Path]::GetFileNameWithoutExtension($docResolved)))-$(Get-Date -Format yyyyMMdd-HHmmss)"
  }
} else {
  $audioResolved = Resolve-Path -LiteralPath $AudioPath
  $sourceAudioHash = Get-FileSha256 $audioResolved
  if (!$ProjectId) {
    $ProjectId = "$(New-Slug ([System.IO.Path]::GetFileNameWithoutExtension($audioResolved)))-$(Get-Date -Format yyyyMMdd-HHmmss)"
  }
}

$outputBase = if ([System.IO.Path]::IsPathRooted($OutputRoot)) {
  $OutputRoot
} else {
  Join-Path (Resolve-Path -LiteralPath ".") $OutputRoot
}
$projectRoot = Join-Path $outputBase $ProjectId
$dirs = @(
  "input", "text", "audio", "subtitles", "references\downloads", "references\muted",
  "references\scene_clips", "assets\free-resource", "assets\selected",
  "timeline", "render\intermediate", "logs"
)
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot $d) | Out-Null }

$keywords = @()
if ($KeySegmentKeywords) {
  $keywords = $KeySegmentKeywords.Split(',', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}
$manualKeyIds = @()
if ($KeySegmentIds) {
  $manualKeyIds = $KeySegmentIds.Split(',', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

$asrTranscript = $null
$asrTranscriptPath = ""
if ($sourceMode -eq "document") {
  Copy-Item -LiteralPath $docResolved -Destination (Join-Path $projectRoot ("input\" + [System.IO.Path]::GetFileName($docResolved))) -Force
  $sourceText = Read-SourceText $docResolved
  $segments = @(Split-IntoSegments -Text $sourceText -MaxChars $MaxSegmentChars -Keywords $keywords)
} else {
  Copy-Item -LiteralPath $audioResolved -Destination (Join-Path $projectRoot ("input\" + [System.IO.Path]::GetFileName($audioResolved))) -Force
  $asrTranscriptPath = Join-Path $projectRoot "text\asr_transcript.json"
  $asrTranscript = Invoke-Asr -AudioPathValue $audioResolved -OutputPath $asrTranscriptPath -Provider $AsrProvider -Command $AsrCommand -Language $AsrLanguage -ExistingTranscriptPath $TranscriptPath
  $sourceText = if ($asrTranscript.text) {
    [string]$asrTranscript.text
  } else {
    (@($asrTranscript.segments | ForEach-Object { $_.text }) -join " ")
  }
  $sourceText = ([regex]::Replace($sourceText, "\s+", " ")).Trim()
  if (!$sourceText) { throw "ASR transcript text is empty." }
  $segments = @(Convert-AsrTranscriptToSegments -Transcript $asrTranscript -AudioDuration (Get-MediaDuration $audioResolved) -MaxChars $MaxSegmentChars -Keywords $keywords)
}

$sourceHash = Get-StringSha256 $sourceText
Write-Utf8File (Join-Path $projectRoot "text\source_text.txt") $sourceText
Write-Utf8File (Join-Path $projectRoot "text\source_text.sha256") $sourceHash

if ($segments.Count -eq 0) { throw "No text segments created." }
$hasExplicitKeyRules = ($keywords.Count -gt 0 -or $manualKeyIds.Count -gt 0)
foreach ($segment in $segments) {
  if ($manualKeyIds -contains $segment.id) {
    $segment.is_key_segment = $true
    $segment.preferred_source = "free-resource"
    $segment | Add-Member -MemberType NoteProperty -Name key_segment_reason -Value "manual_id" -Force
  }
}
$autoKeySegments = @()
if (!$DisableAutoKeySegments -and !$hasExplicitKeyRules -and ($FreeResourceCommand -or $FreeResourceRoot)) {
  $autoKeySegments = @(Set-AutoKeySegments -Segments $segments -Count $AutoKeySegmentCount)
}
Write-Json ([pscustomobject]@{
  source_hash = $sourceHash
  source_mode = $sourceMode
  source_audio_hash = $sourceAudioHash
  asr_provider = $(if ($sourceMode -eq "audio-asr") { if ($AsrProvider -eq "none") { "faster-whisper" } else { $AsrProvider } } else { "" })
  asr_transcript = $(if ($asrTranscriptPath) { Get-RelativePath $projectRoot $asrTranscriptPath } else { "" })
  auto_key_segments = $autoKeySegments
  segments = $segments
}) (Join-Path $projectRoot "text\segments.json")

$narrationPath = Join-Path $projectRoot "audio\narration.wav"
if ($sourceMode -eq "audio-asr") {
  $audioItems = @(New-AudioItemsFromSourceAudio -Segments $segments -SourceAudioPath $audioResolved -AudioDir (Join-Path $projectRoot "audio"))
} else {
  $audioItems = @(New-TtsAudio -Segments $segments -AudioDir (Join-Path $projectRoot "audio") -Voice $VoiceName -Provider $TtsProvider -Command $TtsCommand)
}
Join-AudioFiles -AudioItems $audioItems -ProjectRoot $projectRoot -OutputPath $narrationPath
$audioManifest = [pscustomobject]@{
  provider = $(if ($sourceMode -eq "audio-asr") { "source-audio-asr" } else { $TtsProvider })
  asr_provider = $(if ($sourceMode -eq "audio-asr") { if ($AsrProvider -eq "none") { "faster-whisper" } else { $AsrProvider } } else { "" })
  command = $(if ($TtsProvider -eq "command") { $TtsCommand } else { "" })
  voice = $(if ($VoiceName) { $VoiceName } else { "default" })
  source_hash = $sourceHash
  source_mode = $sourceMode
  source_audio = $(if ($sourceMode -eq "audio-asr") { Get-RelativePath $projectRoot $audioResolved } else { "" })
  source_audio_hash = $sourceAudioHash
  segments = $audioItems | ForEach-Object {
    [pscustomobject]@{
      id = $_.id
      text_hash = $_.text_hash
      audio_path = Get-RelativePath $projectRoot $_.audio_path
      duration_seconds = [math]::Round($_.duration_seconds, 3)
    }
  }
  narration_path = Get-RelativePath $projectRoot $narrationPath
  total_duration_seconds = [math]::Round((Get-MediaDuration $narrationPath), 3)
}
Write-Json $audioManifest (Join-Path $projectRoot "audio\audio_manifest.json")

$srtPath = Join-Path $projectRoot "subtitles\final.srt"
Write-Srt -Segments $segments -AudioItems $audioItems -Path $srtPath

$referenceUrlInputs = @($ReferenceUrl)
if ($ReferenceSearchQuery) {
  $referenceUrlInputs += ("ytsearch{0}:{1}" -f $ReferenceSearchLimit, $ReferenceSearchQuery)
} elseif ($AutoReferenceSearch -and $referenceUrlInputs.Count -eq 0 -and @($ReferenceVideoPath).Count -eq 0) {
  $ReferenceSearchQuery = New-ReferenceSearchQuery -Segments $segments
  $referenceUrlInputs += ("ytsearch{0}:{1}" -f $ReferenceSearchLimit, $ReferenceSearchQuery)
}

$downloaded = @(Download-ReferenceVideos -Urls $referenceUrlInputs -DownloadDir (Join-Path $projectRoot "references\downloads") -CookiesFromBrowser $YtDlpCookiesFromBrowser -CookiesPath $YtDlpCookiesPath)
$localReferences = @()
foreach ($refPath in $ReferenceVideoPath) {
  if (Test-Path -LiteralPath $refPath) { $localReferences += (Resolve-Path -LiteralPath $refPath).Path }
}
$allReferences = @($downloaded + $localReferences)
$referenceClips = @()
$refIndex = 1
foreach ($ref in $allReferences) {
  $muted = Join-Path $projectRoot ("references\muted\reference_{0:000}.mp4" -f $refIndex)
  New-MutedVideo -InputPath $ref -OutputPath $muted
  $clipDir = Join-Path $projectRoot ("references\scene_clips\reference_{0:000}" -f $refIndex)
  $referenceClips += @(Split-ReferenceVideo -InputPath $muted -OutputDir $clipDir -Threshold $SceneThreshold -MinDuration $SceneMinDuration -PreferredMaxDuration $ScenePreferredMaxDuration -MaxDuration $SceneMaxDuration)
  $refIndex += 1
}

if (!$FreeResourceRoot) {
  $FreeResourceRoot = Join-Path $projectRoot "assets\free-resource"
}
New-Item -ItemType Directory -Force -Path $FreeResourceRoot | Out-Null
$freeResourceResults = @(Invoke-FreeResourceForKeySegments -Segments $segments -ProjectRoot $projectRoot -FreeRoot $FreeResourceRoot -Command $FreeResourceCommand -AspectRatioValue $AspectRatio -Require:$RequireFreeResourceForKeySegments)
if ($freeResourceResults.Count -gt 0) {
  Write-Json ([pscustomobject]@{ command = $FreeResourceCommand; results = $freeResourceResults }) (Join-Path $projectRoot "assets\free-resource\free-resource-results.json")
}
$selectedDir = Join-Path $projectRoot "assets\selected"
if ($AspectRatio -eq "9:16") {
  $width = 1080; $height = 1920
} else {
  $width = 1920; $height = 1080
}

$assetPlan = @(Select-VisualAssets -Segments $segments -AudioItems $audioItems -ReferenceClips $referenceClips -FreeRoot $FreeResourceRoot -SelectedDir $selectedDir -Width $width -Height $height)
Write-Json ([pscustomobject]@{
  free_resource_root = Get-RelativePath $projectRoot $FreeResourceRoot
  free_resource_command = $FreeResourceCommand
  free_resource_results = $freeResourceResults
  reference_clip_order = "deterministic-shuffled-before-selection"
  reference_clip_duration_policy = [pscustomobject]@{
    preferred_range_seconds = "5-8"
    preferred_max_duration_seconds = $ScenePreferredMaxDuration
    hard_max_duration_seconds = [math]::Min($SceneMaxDuration, 15.0)
  }
  reference_search_query = $ReferenceSearchQuery
  reference_search_limit = $ReferenceSearchLimit
  yt_dlp_cookies_from_browser = $YtDlpCookiesFromBrowser
  yt_dlp_cookies_path = $(if ($YtDlpCookiesPath) { $YtDlpCookiesPath } else { "" })
  references_used = $allReferences
  segments = $assetPlan | ForEach-Object {
    [pscustomobject]@{
      segment_id = $_.segment_id
      source_type = $_.source_type
      query = $_.query
      selected_asset = Get-RelativePath $projectRoot $_.selected_asset
      candidate_assets = @($_.candidate_assets | ForEach-Object { if ($_ -and (Test-Path -LiteralPath $_)) { Get-RelativePath $projectRoot $_ } else { $_ } })
      selection_policy = $_.selection_policy
      duration_seconds = $_.duration_seconds
    }
  }
}) (Join-Path $projectRoot "timeline\asset_plan.json")

$cursor = 0.0
$timelineSegments = @()
for ($i = 0; $i -lt $segments.Count; $i++) {
  $dur = [double]$audioItems[$i].duration_seconds
  $timelineSegments += [pscustomobject]@{
    segment_id = $segments[$i].id
    start_seconds = [math]::Round($cursor, 3)
    end_seconds = [math]::Round($cursor + $dur, 3)
    duration_seconds = [math]::Round($dur, 3)
    audio = Get-RelativePath $projectRoot $audioItems[$i].audio_path
    visual = Get-RelativePath $projectRoot $assetPlan[$i].selected_asset
    subtitle_text = $segments[$i].text
  }
  $cursor += $dur
}
$timeline = [pscustomobject]@{
  format = [pscustomobject]@{ width = $width; height = $height; fps = 30 }
  source_hash = $sourceHash
  segments = $timelineSegments
  output = "render\final.mp4"
}
Write-Json $timeline (Join-Path $projectRoot "timeline\timeline.json")

$segmentVideos = @(Render-Segments -Segments $segments -AudioItems $audioItems -AssetPlan $assetPlan -ProjectRoot $projectRoot -IntermediateDir (Join-Path $projectRoot "render\intermediate"))
$merged = Join-Path $projectRoot "render\merged.mp4"
Concat-Videos -Videos $segmentVideos -ProjectRoot $projectRoot -OutputPath $merged
$final = Join-Path $projectRoot "render\final.mp4"
Add-SoftSubtitle -InputVideo $merged -SrtPath $srtPath -OutputVideo $final

$burned = $null
if ($BurnSubtitles) {
  $burned = Join-Path $projectRoot "render\final_burned.mp4"
  if (!(Add-BurnedSubtitle -InputVideo $merged -SrtPath $srtPath -OutputVideo $burned)) {
    $burned = $null
  }
}

$result = [pscustomobject]@{
  status = "completed"
  project_id = $ProjectId
  project_root = $projectRoot
  final_video = $final
  burned_video = $burned
  subtitle = $srtPath
  narration = $narrationPath
  timeline = Join-Path $projectRoot "timeline\timeline.json"
  asset_manifest = Join-Path $projectRoot "timeline\asset_plan.json"
  segment_count = $segments.Count
  reference_clip_count = $referenceClips.Count
}
Write-Json $result (Join-Path $projectRoot "render\result.json")
$result | ConvertTo-Json -Depth 6
