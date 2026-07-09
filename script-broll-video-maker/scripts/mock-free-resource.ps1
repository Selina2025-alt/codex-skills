param(
  [Parameter(Mandatory = $true)]
  [string]$RequestPath,

  [Parameter(Mandatory = $true)]
  [string]$OutputDir
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$request = Get-Content -LiteralPath $RequestPath -Raw -Encoding UTF8 | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (!$ffmpeg) { throw "ffmpeg is required for mock-free-resource." }

$output = Join-Path $OutputDir "mock-free-resource.mp4"
$seed = [Math]::Abs(($request.segment_id + $request.query).GetHashCode())
$hue = $seed % 360

& $ffmpeg.Source -y -hide_banner -v error -f lavfi -i "testsrc2=s=1280x720:d=12" -vf "hue=h=$hue" -pix_fmt yuv420p "$output" | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "mock-free-resource failed to generate asset."
}

$manifest = [pscustomobject]@{
  segment_id = $request.segment_id
  source = "mock-free-resource"
  asset_path = $output
  query = $request.query
  license = "test-only"
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $OutputDir "mock-free-resource.json") -Encoding UTF8
