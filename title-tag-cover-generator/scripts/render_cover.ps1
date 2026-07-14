param(
  [string]$LayoutPath = "outputs/cover/cover_layout.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$layout = Get-Content -LiteralPath $LayoutPath -Encoding UTF8 -Raw | ConvertFrom-Json
$outPath = $layout.output
$photoPath = $layout.photo_source

$W = 1086
$H = 1448
$green = [System.Drawing.Color]::FromArgb(45, 255, 0)
$white = [System.Drawing.Color]::FromArgb(248, 248, 248)
$black = [System.Drawing.Color]::FromArgb(0, 0, 0)
$darkGray = [System.Drawing.Color]::FromArgb(18, 18, 18)

function New-Font([string]$Name, [float]$Size, [System.Drawing.FontStyle]$Style) {
  return New-Object System.Drawing.Font($Name, $Size, $Style, [System.Drawing.GraphicsUnit]::Pixel)
}

function Measure-Tracking($g, [string]$Text, $font, [float]$Tracking) {
  $fmt = [System.Drawing.StringFormat]::GenericTypographic
  $sum = 0.0
  foreach ($ch in $Text.ToCharArray()) {
    $sum += $g.MeasureString([string]$ch, $font, 1000, $fmt).Width + $Tracking
  }
  if ($Text.Length -gt 0) { $sum -= $Tracking }
  return $sum
}

function Draw-Tracking($g, [string]$Text, $font, $brush, [float]$X, [float]$Y, [float]$Tracking) {
  $fmt = [System.Drawing.StringFormat]::GenericTypographic
  $cx = $X
  foreach ($ch in $Text.ToCharArray()) {
    $s = [string]$ch
    $g.DrawString($s, $font, $brush, $cx, $Y, $fmt)
    $cx += $g.MeasureString($s, $font, 1000, $fmt).Width + $Tracking
  }
  return $cx
}

function Fit-Font($g, [string]$Text, [string]$FontName, [float]$StartSize, [float]$MaxWidth, [float]$Tracking) {
  $size = $StartSize
  while ($size -gt 30) {
    $font = New-Font $FontName $size ([System.Drawing.FontStyle]::Bold)
    $w = Measure-Tracking $g $Text $font $Tracking
    if ($w -le $MaxWidth) { return $font }
    $font.Dispose()
    $size -= 2
  }
  return New-Font $FontName $size ([System.Drawing.FontStyle]::Bold)
}

function Draw-Star($g, [float]$Cx, [float]$Cy, [float]$R1, [float]$R2, $brush) {
  $pts = New-Object System.Collections.Generic.List[System.Drawing.PointF]
  for ($i = 0; $i -lt 8; $i++) {
    $r = $(if (($i % 2) -eq 0) { $R1 } else { $R2 })
    $a = (-90 + $i * 45) * [Math]::PI / 180.0
    $pts.Add([System.Drawing.PointF]::new($Cx + [Math]::Cos($a) * $r, $Cy + [Math]::Sin($a) * $r))
  }
  $g.FillPolygon($brush, $pts.ToArray())
}

function Draw-OutlinedText($g, [string]$Text, [string]$FontName, [float]$Size, [float]$X, [float]$Y) {
  $family = New-Object System.Drawing.FontFamily($FontName)
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $fmt = [System.Drawing.StringFormat]::GenericTypographic
  $path.AddString($Text, $family, [int][System.Drawing.FontStyle]::Bold, $Size, [System.Drawing.PointF]::new($X, $Y), $fmt)
  $shadowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(70, 70, 70), 5)
  $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 2.2)
  $g.DrawPath($shadowPen, $path)
  $g.DrawPath($pen, $path)
  $shadowPen.Dispose()
  $pen.Dispose()
  $path.Dispose()
  $family.Dispose()
}

$bmp = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.Clear($black)

$brushWhite = New-Object System.Drawing.SolidBrush($white)
$brushBlack = New-Object System.Drawing.SolidBrush($black)
$brushGreen = New-Object System.Drawing.SolidBrush($green)
$penWhite3 = New-Object System.Drawing.Pen($white, 3)
$penWhite2 = New-Object System.Drawing.Pen($white, 2)
$penGreen = New-Object System.Drawing.Pen($green, 5)

# Header line, matching the template's top spacing.
Draw-OutlinedText $g ([string]$layout.title_lines[0]) "YouSheBiaoTiHei" 66 77 140
$g.DrawLine($penGreen, 74, 228, 890, 228)
Draw-Star $g 968 220 44 12 $brushGreen

# Main title line 2.
$line2 = [string]$layout.title_lines[1]
$line2A = "软件工厂时代"
$line2B = "会迫使我们"
$fontName = "Alimama ShuHeiTi"
$font2A = Fit-Font $g $line2 $fontName 91 880 0
$font2B = $font2A
$x = 73
$y2 = 278
$h2 = 122
$w2A = Measure-Tracking $g $line2A $font2A 0
$g.FillRectangle($brushGreen, [System.Drawing.RectangleF]::new($x, $y2 - 8, $w2A + 22, $h2))
[void](Draw-Tracking $g $line2A $font2A $brushBlack ($x + 9) $y2 0)
$x2B = $x + $w2A + 24
[void](Draw-Tracking $g $line2B $font2B $brushWhite $x2B $y2 0)

# Main title line 3.
$line3 = [string]$layout.title_lines[2]
$font3 = Fit-Font $g $line3 $fontName 104 930 0
$x3 = 73
$y3 = 438
$h3 = 122
$w3 = Measure-Tracking $g $line3 $font3 0
$g.FillRectangle($brushGreen, [System.Drawing.RectangleF]::new($x3, $y3 - 8, $w3 + 24, $h3))
[void](Draw-Tracking $g $line3 $font3 $brushBlack ($x3 + 10) $y3 0)

# Photo frame and image area. Match the reference template's image placement.
$outer = [System.Drawing.Rectangle]::new(51, 634, 984, 766)
$photo = [System.Drawing.Rectangle]::new(62, 647, 962, 635)
$g.DrawRectangle($penWhite3, $outer)

$srcImg = [System.Drawing.Image]::FromFile($photoPath)
$srcRatio = $srcImg.Width / $srcImg.Height
$targetRatio = $photo.Width / $photo.Height
if ($srcRatio -gt $targetRatio) {
  $cropH = $srcImg.Height
  $cropW = [int]($cropH * $targetRatio)
  $cropX = [int](($srcImg.Width - $cropW) / 2)
  $cropY = 0
} else {
  $cropW = $srcImg.Width
  $cropH = [int]($cropW / $targetRatio)
  $cropX = 0
  $cropY = [int](($srcImg.Height - $cropH) / 2)
}
$crop = [System.Drawing.Rectangle]::new($cropX, $cropY, $cropW, $cropH)

$cm = New-Object System.Drawing.Imaging.ColorMatrix
$cm.Matrix00 = 0.299; $cm.Matrix01 = 0.299; $cm.Matrix02 = 0.299
$cm.Matrix10 = 0.587; $cm.Matrix11 = 0.587; $cm.Matrix12 = 0.587
$cm.Matrix20 = 0.114; $cm.Matrix21 = 0.114; $cm.Matrix22 = 0.114
$cm.Matrix33 = 1.0
$cm.Matrix44 = 1.0
$ia = New-Object System.Drawing.Imaging.ImageAttributes
$ia.SetColorMatrix($cm)
$g.DrawImage($srcImg, $photo, $crop.X, $crop.Y, $crop.Width, $crop.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
$srcImg.Dispose()
$ia.Dispose()

# Frame details and logo/tag reserved spaces.
$g.DrawRectangle($penWhite2, $photo)
$g.DrawRectangle($penWhite3, $outer)

# Minimal corner marks inspired by the template.
$cornerPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(235,235,235), 2)
$g.DrawLine($cornerPen, 62, 647, 170, 647)
$g.DrawLine($cornerPen, 62, 647, 62, 755)
$g.DrawLine($cornerPen, 916, 647, 1024, 647)
$g.DrawLine($cornerPen, 1024, 647, 1024, 755)
$g.DrawLine($cornerPen, 62, 1188, 170, 1188)
$g.DrawLine($cornerPen, 62, 1080, 62, 1188)
$g.DrawLine($cornerPen, 916, 1188, 1024, 1188)
$g.DrawLine($cornerPen, 1024, 1080, 1024, 1188)
$cornerPen.Dispose()

New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($outPath)) | Out-Null
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)

$penWhite3.Dispose(); $penWhite2.Dispose(); $penGreen.Dispose()
$brushWhite.Dispose(); $brushBlack.Dispose(); $brushGreen.Dispose()
$font2A.Dispose(); $font3.Dispose()
$g.Dispose()
$bmp.Dispose()

Write-Output $outPath
