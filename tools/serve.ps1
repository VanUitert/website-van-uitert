# Lokale testserver: toont de website op http://localhost:8377/
# Gebruik:  powershell -ExecutionPolicy Bypass -File tools\serve.ps1
param([int]$Port = 8377)
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$mime = @{ '.html'='text/html; charset=utf-8'; '.css'='text/css'; '.js'='application/javascript'; '.svg'='image/svg+xml';
           '.png'='image/png'; '.jpg'='image/jpeg'; '.webp'='image/webp'; '.txt'='text/plain' }
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add("http://localhost:$Port/")
$l.Start()
Write-Host "Website staat op http://localhost:$Port/  (stoppen met Ctrl+C)"
while ($l.IsListening) {
  $c = $l.GetContext()
  try {
    $p = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath).TrimStart('/')
    if ($p -eq '' -or $p.EndsWith('/')) { $p += 'index.html' }
    $full = [IO.Path]::GetFullPath((Join-Path $root $p))
    if ($c.Request.HttpMethod -eq 'GET' -and $full.StartsWith($root) -and (Test-Path $full -PathType Leaf)) {
      $b = [IO.File]::ReadAllBytes($full)
      $c.Response.ContentType = $mime[[IO.Path]::GetExtension($full).ToLower()]
    } else {
      $c.Response.StatusCode = 404
      $b = [IO.File]::ReadAllBytes((Join-Path $root '404.html'))
      $c.Response.ContentType = 'text/html; charset=utf-8'
    }
    $c.Response.Headers.Add('Cache-Control', 'no-store')
    $c.Response.OutputStream.Write($b, 0, $b.Length)
  } catch {} finally { $c.Response.Close() }
}
