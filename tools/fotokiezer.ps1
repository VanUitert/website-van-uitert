# Fotokiezer: de beeldbank doorzoeken op kenmerken en per plek op de site zelf de foto kiezen.
# Starten: dubbelklik tools\Fotokiezer.cmd, of: powershell -ExecutionPolicy Bypass -File tools\fotokiezer.ps1 -Open
# Leest de beeldbank alleen. Schrijft alleen in deze map: assets/img, src en de werkmap .fotokiezer.
param([int]$Port = 8378, [string]$Bank = 'L:\Marketing\Van Uitert B.V. 2.0',
      [string[]]$Mappen = @('01. Beeldbank - Projecten', '02. Beeldbank - Producten', '03. Beeldbank - Bedrijf & Pand'), [switch]$Open)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing, System.Web.Extensions, PresentationCore, WindowsBase
Add-Type -Path (Join-Path $PSScriptRoot 'filter\Lut.cs') -ReferencedAssemblies System.Drawing
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$werk = Join-Path $root '.fotokiezer'; $cache = Join-Path $werk 'cache'; $oudMap = Join-Path $werk 'oud'
foreach ($d in $werk, $cache, $oudMap) { [void][IO.Directory]::CreateDirectory($d) }
$img = Join-Path $root 'assets\img'; $lijst = Join-Path $img 'sizes.txt'
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer; $ser.MaxJsonLength = 64MB
$utf8 = New-Object Text.UTF8Encoding($false)
$sha = [Security.Cryptography.SHA1]::Create()
$bash = @('C:\Program Files\Git\bin\bash.exe', (Join-Path (Split-Path (Split-Path (Get-Command git).Source)) 'bin\bash.exe')) | Where-Object { Test-Path $_ } | Select-Object -First 1
$mime = @{ '.html'='text/html; charset=utf-8'; '.css'='text/css'; '.js'='application/javascript'; '.svg'='image/svg+xml';
           '.png'='image/png'; '.jpg'='image/jpeg'; '.webp'='image/webp'; '.txt'='text/plain' }

function Hash([string]$s, [int]$n = 16) { (-join ($sha.ComputeHash($utf8.GetBytes($s)) | ForEach-Object { $_.ToString('x2') })).Substring(0, $n) }
function Regels([string]$pad) { if (Test-Path $pad) { ,[IO.File]::ReadAllLines($pad, $utf8) } else { ,[string[]]@() } }
function Schrijf([string]$pad, $regels) { [IO.File]::WriteAllText($pad, ((@($regels) -join "`n") + "`n"), $utf8) }

# ---- index van de beeldbank: pad, breedte, hoogte, stand, grootte, datum ----
$indexPad = Join-Path $werk 'index.tsv'
$script:fotos = New-Object 'System.Collections.Generic.Dictionary[string,object]'
foreach ($r in (Regels $indexPad)) { $v = $r.Split("`t"); if ($v.Length -eq 6) { $script:fotos[$v[0]] = @([int]$v[1], [int]$v[2], [int]$v[3], [long]$v[4], [long]$v[5]) } }
$script:todo = $null; $script:nieuw = $null; $script:pos = 0
function IndexStart {
  if (-not (Test-Path $Bank)) { throw "De beeldbank is niet bereikbaar: $Bank" }
  $script:todo = New-Object 'System.Collections.Generic.List[object]'
  foreach ($m in $Mappen) { $p = Join-Path $Bank $m; if (-not (Test-Path $p)) { continue }
    foreach ($f in (New-Object IO.DirectoryInfo $p).EnumerateFiles('*', 'AllDirectories')) { if ($f.Extension -match '^\.(jpe?g|png)$') { $script:todo.Add($f) } } }
  $script:nieuw = New-Object 'System.Collections.Generic.Dictionary[string,object]'; $script:pos = 0
}
function IndexStap([int]$ms = 1200) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while ($script:pos -lt $script:todo.Count -and $sw.ElapsedMilliseconds -lt $ms) {
    $fi = $script:todo[$script:pos]; $script:pos++
    $rel = $fi.FullName.Substring($Bank.Length + 1); $oud = $null
    if ($script:fotos.TryGetValue($rel, [ref]$oud) -and $oud[3] -eq $fi.Length -and $oud[4] -eq $fi.LastWriteTimeUtc.Ticks) { $script:nieuw[$rel] = $oud; continue }
    $w = 0; $h = 0; $o = 1
    try { $fs = $fi.OpenRead()
      try { $im = [Drawing.Image]::FromStream($fs, $false, $false); $w = $im.Width; $h = $im.Height
        if ($im.PropertyIdList -contains 0x0112) { $o = [int]$im.GetPropertyItem(0x0112).Value[0] }; $im.Dispose() } finally { $fs.Dispose() } } catch {}
    if ($o -eq 6 -or $o -eq 8) { $w, $h = $h, $w }
    $script:nieuw[$rel] = @([int]$w, [int]$h, [int]$o, [long]$fi.Length, [long]$fi.LastWriteTimeUtc.Ticks)
  }
  if ($script:pos -ge $script:todo.Count) {
    $script:fotos = $script:nieuw; $uit = New-Object 'System.Collections.Generic.List[string]'
    foreach ($k in $script:fotos.Keys) { $v = $script:fotos[$k]; $uit.Add(($k, $v[0], $v[1], $v[2], $v[3], $v[4]) -join "`t") }
    Schrijf $indexPad $uit; $n = $script:todo.Count; $script:todo = $null; return @{ klaar = $true; pos = $n; totaal = $n }
  }
  return @{ klaar = $false; pos = $script:pos; totaal = $script:todo.Count }
}

# ---- eigen kenmerken per foto ----
$kenPad = Join-Path $werk 'kenmerken.tsv'
$script:eigen = New-Object 'System.Collections.Generic.Dictionary[string,object]'
foreach ($r in (Regels $kenPad)) { $v = $r.Split("`t"); if ($v.Length -eq 2 -and $v[1]) { $script:eigen[$v[0]] = $v[1] } }
function KenmerkBewaar { $uit = New-Object 'System.Collections.Generic.List[string]'; foreach ($k in $script:eigen.Keys) { $uit.Add($k + "`t" + $script:eigen[$k]) }; Schrijf $kenPad $uit }

# ---- plekken op de site: elke foto in src/pages en src/partials ----
$geenPlek = 'job-van-uitert', 'ad-van-den-berg', 'maaike'
function SrcBestanden { @([IO.Directory]::GetFiles((Join-Path $root 'src\pages'), '*.html')) + @([IO.Directory]::GetFiles((Join-Path $root 'src\partials'), '*.html')) }
function Schoon([string]$t) { [Net.WebUtility]::HtmlDecode(([regex]::Replace($t, '<[^>]*>', ''))).Trim() }
function Plekken {
  $uit = New-Object 'System.Collections.Generic.List[object]'
  $bron = @{}; foreach ($r in (Regels (Join-Path $werk 'bronnen.tsv'))) { $v = $r.Split("`t"); if ($v.Length -ge 2) { $bron[$v[0]] = $v[1] } }
  $gebouwd = @{}
  foreach ($b in (SrcBestanden)) {
    $rel = $b.Substring($root.Length + 1).Replace('\', '/'); $kort = [IO.Path]::GetFileNameWithoutExtension($b)
    $regels = [IO.File]::ReadAllLines($b, $utf8); $tel = @{}
    for ($i = 0; $i -lt $regels.Length; $i++) {
      foreach ($m in [regex]::Matches($regels[$i], '<img[^>]*?src="assets/img/([^"/]+\.(?:jpg|png|webp))"[^>]*>')) {
        $naam = $m.Groups[1].Value; $basis = [IO.Path]::GetFileNameWithoutExtension($naam)
        if ($basis -like 'logo*' -or $geenPlek -contains $basis) { continue }
        $nr = [int]$tel[$naam]; $tel[$naam] = $nr + 1
        $alt = Schoon ([regex]::Match($m.Value, 'alt="([^"]*)"').Groups[1].Value)
        $ctx = $regels[$i].Substring($m.Index + $m.Length)
        for ($j = $i + 1; $j -le $i + 6 -and $j -lt $regels.Length; $j++) { $ctx += ' ' + $regels[$j] }
        $label = Schoon ([regex]::Match($ctx, '(?:class="eyebrow">|<b>|<h[123][^>]*>)(.*?)</(?:span|b|h[123])>').Groups[1].Value)
        if ($m.Value -match 'class="bg"') { $label = 'Achtergrond bovenaan' }
        if (-not $label) { $label = $alt }; if (-not $label) { $label = $basis }
        if ($rel -like 'src/pages/*') { $pagina = "$kort.html"; $titel = if ($kort -eq 'index') { 'Home' } else { $kort.Substring(0, 1).ToUpper() + $kort.Substring(1).Replace('-', ' ') } }
        else {
          $nr = 0; $titel = if ($kort -like 'card-*') { 'Projectkaart' } else { $kort }; $pagina = $null
          foreach ($p in @('projects.html') + @([IO.Directory]::GetFiles($root, '*.html') | ForEach-Object { [IO.Path]::GetFileName($_) })) {
            if (-not $gebouwd.ContainsKey($p)) { $gebouwd[$p] = [IO.File]::ReadAllText((Join-Path $root $p), $utf8) }
            if ($gebouwd[$p].Contains("assets/img/$naam")) { $pagina = $p; break } }
          if (-not $pagina) { continue }
        }
        $klein = $naam
        foreach ($r in (Regels $lijst)) { $v = $r.Split(' '); if ($v[0] -eq $basis -and $v.Length -ge 3) { $klein = "$basis-$($v[2]).jpg" } }
        $uit.Add(@{ bestand = $rel; regel = $i + 1; naam = $naam; nr = $nr; label = [string]$label; alt = [string]$alt; pagina = [string]$pagina; titel = [string]$titel; klein = [string]$klein; bron = [string]$bron[$naam] })
      }
    }
  }
  return ,$uit
}

# ---- foto's op de site: vervangen, opruimen, terugzetten, bouwen ----
function Verwijzingen([string]$naam) {
  $n = 0; $zoek = "img/$naam"
  $alle = @(SrcBestanden) + @([IO.Directory]::GetFiles((Join-Path $root 'assets\css'), '*.css')) + @([IO.Directory]::GetFiles((Join-Path $root 'assets\js'), '*.js'))
  foreach ($b in $alle) { if ([IO.File]::ReadAllText($b, $utf8).Contains($zoek)) { $n++ } }
  return $n
}
function Opruimen([string]$naam) {   # niet meer gebruikte foto naar .fotokiezer\oud, zodat hij niet online blijft staan
  if ((Verwijzingen $naam) -gt 0) { return }
  $basis = [IO.Path]::GetFileNameWithoutExtension($naam); $weg = @($naam); $houd = @()
  foreach ($r in (Regels $lijst)) { $v = $r.Split(' '); if ($v[0] -eq $basis) { $weg += "$basis-$($v[2]).jpg"; [IO.File]::WriteAllText((Join-Path $oudMap "$basis.sizes"), $r, $utf8) } elseif ($r) { $houd += $r } }
  Schrijf $lijst $houd
  foreach ($f in $weg) { $van = Join-Path $img $f; if (Test-Path $van) { Move-Item $van (Join-Path $oudMap $f) -Force } }
}
function Herstel([string]$naam) {
  if (Test-Path (Join-Path $img $naam)) { return }
  if (-not (Test-Path (Join-Path $oudMap $naam))) { throw "De vorige foto $naam is niet meer te vinden." }
  $basis = [IO.Path]::GetFileNameWithoutExtension($naam); Move-Item (Join-Path $oudMap $naam) (Join-Path $img $naam) -Force
  $sz = Join-Path $oudMap "$basis.sizes"
  if (Test-Path $sz) { $r = [IO.File]::ReadAllText($sz, $utf8).Trim(); $v = $r.Split(' '); $kl = "$basis-$($v[2]).jpg"
    if (Test-Path (Join-Path $oudMap $kl)) { Move-Item (Join-Path $oudMap $kl) (Join-Path $img $kl) -Force }
    $houd = @(); foreach ($x in (Regels $lijst)) { if ($x -and $x.Split(' ')[0] -ne $basis) { $houd += $x } }
    Schrijf $lijst ($houd + $r); Remove-Item $sz }
}
function Vervang([string]$bestand, [int]$regel, [string]$oud, [string]$nieuw, [bool]$overal) {
  $van = "assets/img/$oud`""; $naar = "assets/img/$nieuw`""
  if ($overal) { foreach ($b in (SrcBestanden)) { $t = [IO.File]::ReadAllText($b, $utf8); if ($t.Contains($van)) { [IO.File]::WriteAllText($b, $t.Replace($van, $naar), $utf8) } } }
  else { $b = Join-Path $root $bestand.Replace('/', '\'); $r = [IO.File]::ReadAllText($b, $utf8).Split("`n"); $r[$regel - 1] = $r[$regel - 1].Replace($van, $naar); [IO.File]::WriteAllText($b, ($r -join "`n"), $utf8) }
}
function Bouw {
  $psi = New-Object Diagnostics.ProcessStartInfo $bash, 'tools/build.sh'
  $psi.WorkingDirectory = $root; $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.CreateNoWindow = $true
  $p = [Diagnostics.Process]::Start($psi); $o = $p.StandardOutput.ReadToEnd(); $e = $p.StandardError.ReadToEnd(); $p.WaitForExit()
  if ($p.ExitCode -ne 0) { throw "Bouwen van de pagina's is mislukt: $e $o" }
}

# ---- miniatuur en voorbeeld ----
function Miniatuur([string]$rel) {
  $v = $script:fotos[$rel]; $dst = Join-Path $cache ('t-' + (Hash "$rel|$($v[3])|$($v[4])") + '.jpg')
  if (Test-Path $dst) { return $dst }
  $src = Join-Path $Bank $rel; $o = [int]$v[2]
  try {
    $fs = [IO.File]::OpenRead($src)
    try { $bi = New-Object Windows.Media.Imaging.BitmapImage; $bi.BeginInit(); $bi.CacheOption = 'OnLoad'; $bi.CreateOptions = 'IgnoreColorProfile'
      if ($o -eq 6 -or $o -eq 8) { $bi.DecodePixelHeight = 420 } else { $bi.DecodePixelWidth = 420 }
      $bi.StreamSource = $fs; $bi.EndInit() } finally { $fs.Dispose() }
    $beeld = $bi; $hoek = @{ 3 = 180; 6 = 90; 8 = 270 }[$o]
    if ($hoek) { $beeld = New-Object Windows.Media.Imaging.TransformedBitmap($bi, (New-Object Windows.Media.RotateTransform($hoek))) }
    $enc = New-Object Windows.Media.Imaging.JpegBitmapEncoder; $enc.QualityLevel = 80; $enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($beeld))
    $ut = [IO.File]::Create($dst); try { $enc.Save($ut) } finally { $ut.Dispose() }
  } catch {
    if (Test-Path $dst) { Remove-Item $dst }
    $ms = New-Object IO.MemoryStream(, [IO.File]::ReadAllBytes($src)); $im = [Drawing.Image]::FromStream($ms)
    switch ($o) { 6 { $im.RotateFlip('Rotate90FlipNone') } 8 { $im.RotateFlip('Rotate270FlipNone') } 3 { $im.RotateFlip('Rotate180FlipNone') } }
    $t = [Lut]::Schaal($im, 420, [int][Math]::Round($im.Height * 420 / $im.Width)); $t.Save($dst, [Drawing.Imaging.ImageFormat]::Jpeg); $t.Dispose(); $im.Dispose(); $ms.Dispose()
  }
  return $dst
}
function Voorbeeld([string]$rel, [bool]$filter) {   # zelfde bewerking als de foto op de site krijgt
  $v = $script:fotos[$rel]; $naam = 'v-' + (Hash "$rel|$filter|$($v[3])|$($v[4])"); $dst = Join-Path $cache "$naam.jpg"
  if (-not (Test-Path $dst)) { $null = & (Join-Path $PSScriptRoot 'foto.ps1') -Bron (Join-Path $Bank $rel) -Naam $naam -Filter:$filter -Map $cache 3>$null }
  return $dst
}
function Slug([string]$t) {
  $s = [regex]::Replace($t.ToLower().Normalize('FormD'), '[^a-z0-9]+', '-').Trim('-')
  if ($s.Length -gt 44) { $s = $s.Substring(0, 44).Trim('-') }
  if (-not $s -or $s -like 'logo*') { $s = "foto-$s".Trim('-') }
  return $s
}
function Kies($d) {
  $bestand = [string]$d['bestand']; $regel = [int]$d['regel']; $oud = [string]$d['oud']; $overal = [bool]$d['overal']
  $plek = $null; foreach ($p in (Plekken)) { if ($p.bestand -eq $bestand -and $p.regel -eq $regel -and $p.naam -eq $oud) { $plek = $p } }
  if (-not $plek) { throw 'Deze plek is niet meer gevonden. Ververs de pagina en probeer het opnieuw.' }
  if ($d.ContainsKey('terug')) {
    $nieuw = [string]$d['terug']; if ($nieuw -notmatch '^[A-Za-z0-9_-]+\.(jpg|png|webp)$') { throw 'Ongeldige naam.' }
    Herstel $nieuw
  } else {
    $rel = [string]$d['rel']; $filter = [bool]$d['filter']
    if (-not $script:fotos.ContainsKey($rel)) { throw 'Deze foto staat niet in de index. Lees de beeldbank opnieuw in.' }
    if ($script:fotos[$rel][0] -lt 800) { throw 'Deze foto is te klein voor de site (minder dan 800 px breed).' }
    $tekst = if ($plek.alt) { $plek.alt } else { "$($plek.titel) $($plek.label)" }
    $naam = (Slug $tekst) + '-' + (Hash "$rel|$filter" 4); $g = 1400; $k = 800; $vak = '50vw'
    foreach ($r in (Regels $lijst)) { $v = $r.Split(' '); if ($v[0] -eq [IO.Path]::GetFileNameWithoutExtension($oud) -and $v.Length -ge 4) { $k = [int]$v[2]; $vak = $v[3]; if ($vak -eq '100vw') { $g = 1600 } } }
    $null = & (Join-Path $PSScriptRoot 'foto.ps1') -Bron (Join-Path $Bank $rel) -Naam $naam -Filter:$filter -Groot $g -Klein $k -Vak $vak 3>$null
    $nieuw = "$naam.jpg"
    [IO.File]::AppendAllText((Join-Path $werk 'bronnen.tsv'), ((($nieuw, $rel, $filter, (Get-Date -Format 'yyyy-MM-dd HH:mm')) -join "`t") + "`n"), $utf8)
  }
  if ($nieuw -ne $oud) { Vervang $bestand $regel $oud $nieuw $overal; Opruimen $oud }
  Bouw
  return @{ ok = $true; naam = $nieuw }
}

# ---- webserver ----
function Stuur($c, [byte[]]$b, [string]$type, [int]$code = 200, [string]$bewaar = 'no-store') {
  $c.Response.StatusCode = $code; $c.Response.ContentType = $type; $c.Response.Headers.Add('Cache-Control', $bewaar); $c.Response.OutputStream.Write($b, 0, $b.Length) }
function Json($c, $obj, [int]$code = 200) { Stuur $c $utf8.GetBytes($ser.Serialize($obj)) 'application/json; charset=utf-8' $code }
function Vraag($c, [string]$naam) {
  foreach ($deel in $c.Request.Url.Query.TrimStart('?').Split('&')) { $kv = $deel.Split('=', 2); if ($kv[0] -eq $naam -and $kv.Length -eq 2) { return [Uri]::UnescapeDataString($kv[1]) } }
  return $null
}
function Invoer($c) {   # eigen kop verplicht: een andere website kan zo niets laten wijzigen
  if ($c.Request.Headers['X-Fotokiezer'] -ne '1') { throw 'Geen toegang.' }
  $rd = New-Object IO.StreamReader($c.Request.InputStream, $utf8); $t = $rd.ReadToEnd()
  if ($t) { return $ser.DeserializeObject($t) }; return @{}
}
function Data {
  $pl = Plekken
  $f = New-Object 'System.Collections.Generic.List[object]'
  foreach ($k in $script:fotos.Keys) { $v = $script:fotos[$k]; if ($v[0] -gt 0) { $f.Add([object[]]@([string]$k, [int]$v[0], [int]$v[1], [long]$v[3], ([DateTime][long]$v[4]).ToString('yyyy-MM-dd'))) } }
  return @{ bank = $Bank; bereikbaar = [bool](Test-Path $Bank); fotos = $f.PSObject.BaseObject; eigen = $script:eigen.PSObject.BaseObject; plekken = $pl.PSObject.BaseObject }
}

$l = New-Object System.Net.HttpListener; $l.Prefixes.Add("http://localhost:$Port/")
$adres = "http://localhost:$Port/kiezer/"
try { $l.Start() } catch { Write-Host "De fotokiezer draait al op $adres"; if ($Open) { Start-Process $adres }; return }
Write-Host "Fotokiezer staat op $adres  (stoppen: dit venster sluiten)"
if ($Open) { Start-Process $adres }
while ($l.IsListening) {
  $c = $l.GetContext()
  try {
    $p = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath).TrimStart('/'); $post = $c.Request.HttpMethod -eq 'POST'
    if ($p -eq 'kiezer' -or $p -eq 'kiezer/') { Stuur $c ([IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'fotokiezer\index.html'))) $mime['.html'] }
    elseif ($p -eq 'api/data') { Json $c (Data) }
    elseif ($p -eq 'api/inlezen' -and $post) { $null = Invoer $c; if (-not $script:todo) { IndexStart }; Json $c (IndexStap) }
    elseif ($p -eq 'api/thumb' -or $p -eq 'api/voorbeeld') {
      $rel = Vraag $c 'p'; if (-not $rel -or -not $script:fotos.ContainsKey($rel)) { throw 'Onbekende foto.' }
      $pad = if ($p -eq 'api/thumb') { Miniatuur $rel } else { Voorbeeld $rel ((Vraag $c 'f') -eq '1') }
      Stuur $c ([IO.File]::ReadAllBytes($pad)) 'image/jpeg' 200 'max-age=604800'
    }
    elseif ($p -eq 'api/kies' -and $post) { Json $c (Kies (Invoer $c)) }
    elseif ($p -eq 'api/kenmerk' -and $post) {
      $d = Invoer $c; $tekst = ([string]$d['tekst']).Replace("`t", ' ').Replace("`n", ' ').Trim()
      foreach ($rel in $d['rels']) {
        $rel = [string]$rel; if (-not $script:fotos.ContainsKey($rel)) { continue }
        if ($d['erbij']) {
          $oud = ''; if ($script:eigen.ContainsKey($rel)) { $oud = [string]$script:eigen[$rel] }
          $delen = @($oud.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }); if ($tekst -and $delen -notcontains $tekst) { $delen += $tekst }
          $script:eigen[$rel] = [string]($delen -join ', ')
        } elseif ($tekst) { $script:eigen[$rel] = $tekst } else { [void]$script:eigen.Remove($rel) }
      }
      KenmerkBewaar; Json $c @{ ok = $true; eigen = $script:eigen.PSObject.BaseObject }
    }
    elseif ($p -like 'api/*') { Json $c @{ fout = 'Onbekende vraag.' } 404 }
    else {
      if ($p -eq '' -or $p.EndsWith('/')) { $p += 'index.html' }
      $full = [IO.Path]::GetFullPath((Join-Path $root $p))
      if (-not $post -and $full.StartsWith($root) -and $p -notmatch '(^|/)\.' -and (Test-Path $full -PathType Leaf)) { Stuur $c ([IO.File]::ReadAllBytes($full)) ([string]$mime[[IO.Path]::GetExtension($full).ToLower()]) }
      else { Stuur $c ([IO.File]::ReadAllBytes((Join-Path $root '404.html'))) $mime['.html'] 404 }
    }
  } catch { try { Json $c @{ fout = $_.Exception.Message } 500 } catch {} } finally { try { $c.Response.Close() } catch {} }
}
