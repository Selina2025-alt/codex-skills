param(
  [Parameter(Mandatory = $true)]
  [string]$RequestPath,

  [Parameter(Mandatory = $true)]
  [string]$OutputPath
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-StringSha256 {
  param([string]$Text)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
  return ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant()
}

$request = Get-Content -LiteralPath $RequestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (!$request.text) { throw "TTS request is missing text." }
if ($request.text_hash -and (Get-StringSha256 $request.text) -ne $request.text_hash) {
  throw "TTS request text_hash does not match text."
}

$dir = Split-Path -Parent $OutputPath
if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

Add-Type -AssemblyName System.Speech
$synth = [System.Speech.Synthesis.SpeechSynthesizer]::new()
try {
  if ($request.voice) { $synth.SelectVoice($request.voice) }
  $synth.Volume = 100
  $synth.Rate = 0
  $synth.SetOutputToWaveFile($OutputPath)
  $synth.Speak($request.text)
  $synth.SetOutputToNull()
} finally {
  $synth.Dispose()
}

if (!(Test-Path -LiteralPath $OutputPath)) {
  throw "Mock TTS provider did not create output audio: $OutputPath"
}

[pscustomobject]@{
  status = "completed"
  segment_id = $request.segment_id
  output_audio = $OutputPath
  text_hash = $request.text_hash
} | ConvertTo-Json -Depth 4
