# Foto toevoegen of vervangen: maakt een groot (1400 px) en een klein (800 px) formaat in assets/img
# en zet de regel in assets/img/sizes.txt. Daarna: bash tools/build.sh
# Gebruik: powershell -ExecutionPolicy Bypass -File tools\foto.ps1 -Bron "L:\...\foto.jpg" -Naam m-rinser -Filter
# -Filter zet het Van Uitert-fotofilter erop (geleerd uit de bewerkte foto's in de beeldbank, preset UitertBV).
# Alleen gebruiken bij een onbewerkt origineel; een foto uit een map "Bewerkt" heeft het filter al.
param([Parameter(Mandatory)][string]$Bron, [Parameter(Mandatory)][string]$Naam, [switch]$Filter, [int]$Groot = 1400, [int]$Klein = 800, [string]$Vak = '50vw')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -Path (Join-Path $PSScriptRoot 'filter\Lut.cs') -ReferencedAssemblies System.Drawing
$map = Join-Path (Split-Path $PSScriptRoot -Parent) 'assets\img'
$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
function Jpg($bmp, [int]$q, [string]$dst) { $ep = New-Object System.Drawing.Imaging.EncoderParameters(1); $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$q); $bmp.Save($dst, $codec, $ep) }
$ms = New-Object IO.MemoryStream(,[IO.File]::ReadAllBytes($Bron)); $img = [System.Drawing.Image]::FromStream($ms)
if ($img.PropertyIdList -contains 0x0112) { switch ($img.GetPropertyItem(0x0112).Value[0]) { 6 { $img.RotateFlip('Rotate90FlipNone') } 8 { $img.RotateFlip('Rotate270FlipNone') } 3 { $img.RotateFlip('Rotate180FlipNone') } } }
if ($img.Width -lt 1000) { Write-Warning "Bron is maar $($img.Width) px breed: te klein voor een scherpe foto op een laptop." }
$bw = [Math]::Min($Groot, $img.Width); $bh = [int][Math]::Round($img.Height * $bw / $img.Width)
$g = [Lut]::Schaal($img, $bw, $bh)
if ($Filter) { [Lut]::Laad((Join-Path $PSScriptRoot 'filter\uitert-filter.lut')); [Lut]::Pas($g) }
$k = [Lut]::Schaal($g, $Klein, [int][Math]::Round($bh * $Klein / $bw))
Jpg $g 78 (Join-Path $map "$Naam.jpg"); Jpg $k 74 (Join-Path $map "$Naam-$Klein.jpg")
$g.Dispose(); $k.Dispose(); $img.Dispose(); $ms.Dispose()
$lijst = Join-Path $map 'sizes.txt'
$regels = @(); if (Test-Path $lijst) { $regels = @(Get-Content $lijst | Where-Object { $_ -and ($_ -split ' ')[0] -ne $Naam }) }
$regels += "$Naam $bw $Klein $Vak"
[IO.File]::WriteAllText($lijst, (($regels -join "`n") + "`n"), (New-Object Text.UTF8Encoding($false)))
"$Naam.jpg: $bw px, $([int]((Get-Item (Join-Path $map "$Naam.jpg")).Length/1kb)) kB; $Naam-$Klein.jpg: $([int]((Get-Item (Join-Path $map "$Naam-$Klein.jpg")).Length/1kb)) kB"
