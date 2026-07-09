param(
  [Parameter(Mandatory = $true)]
  [string]$RequestPath,

  [Parameter(Mandatory = $true)]
  [string]$OutputPath
)

$ErrorActionPreference = "Stop"
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
  $PSNativeCommandUseErrorActionPreference = $false
}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Read-JsonFile {
  param([string]$Path)
  return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

$request = Read-JsonFile -Path $RequestPath
$audioPath = [string]$request.audio_path
$language = if ($request.language) { [string]$request.language } else { "zh" }

$whisperExe = if ($env:WHISPER_CPP_EXE) {
  $env:WHISPER_CPP_EXE
} else {
  $cmd = Get-Command whisper-cli -ErrorAction SilentlyContinue
  if ($cmd) { $cmd.Source } else { "" }
}
$modelPath = if ($env:WHISPER_CPP_MODEL) { $env:WHISPER_CPP_MODEL } else { "" }
$threads = if ($env:WHISPER_CPP_THREADS) { [int]$env:WHISPER_CPP_THREADS } else { 8 }

if (!$whisperExe -or !(Test-Path -LiteralPath $whisperExe)) { throw "whisper.cpp executable missing. Set WHISPER_CPP_EXE or put whisper-cli in PATH." }
if (!$modelPath -or !(Test-Path -LiteralPath $modelPath)) { throw "whisper.cpp model missing. Set WHISPER_CPP_MODEL to a ggml model file." }
if (!(Test-Path -LiteralPath $audioPath)) { throw "ASR audio file missing: $audioPath" }

$outDir = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$basePath = Join-Path $outDir "whisper-cpp-transcript"
$rawJson = "$basePath.json"

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
  $commandOutput = @(& $whisperExe -m $modelPath -f $audioPath -l $language -oj -ojf -of $basePath -np -t $threads 2>&1)
  $exitCode = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
}

if ($exitCode -ne 0) {
  throw "whisper.cpp ASR failed with exit code $exitCode. $($commandOutput -join ' ')"
}
if (!(Test-Path -LiteralPath $rawJson)) { throw "whisper.cpp did not create JSON transcript: $rawJson" }

$converter = Join-Path $PSScriptRoot "convert-whisper-cpp-json.py"
if (!(Test-Path -LiteralPath $converter)) { throw "whisper.cpp converter missing: $converter" }
$python = if (Get-Command python -ErrorAction SilentlyContinue) { (Get-Command python).Source } elseif (Get-Command python3 -ErrorAction SilentlyContinue) { (Get-Command python3).Source } else { "" }
if (!$python) { throw "python is required to convert whisper.cpp JSON." }

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
  $convertOutput = @(& $python $converter --input $rawJson --output $OutputPath --audio $audioPath --language $language 2>&1)
  $convertExitCode = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
}

if ($convertExitCode -ne 0) {
  throw "whisper.cpp JSON conversion failed with exit code $convertExitCode. $($convertOutput -join ' ')"
}
if (!(Test-Path -LiteralPath $OutputPath)) { throw "ASR transcript was not created: $OutputPath" }
