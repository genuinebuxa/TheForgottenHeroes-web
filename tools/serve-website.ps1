# Serves this website on http://localhost:8080 for a local preview (Ctrl+C stops it).
param([int]$Port = 8080)
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$types = @{
    '.html' = 'text/html; charset=utf-8'; '.css' = 'text/css'; '.js' = 'text/javascript'
    '.png' = 'image/png'; '.jpg' = 'image/jpeg'; '.webp' = 'image/webp'; '.svg' = 'image/svg+xml'
    '.ttf' = 'font/ttf'; '.txt' = 'text/plain; charset=utf-8'
}
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Website: http://localhost:$Port/"
try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        try {
        $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
        $file = Join-Path $root $path
        if (Test-Path $file -PathType Container) { $file = Join-Path $file 'index.html' }
        $status = 200
        if (-not (Test-Path $file -PathType Leaf) -or -not $file.StartsWith($root)) {
            $file = Join-Path $root '404.html'; $status = 404
        }
        $bytes = [IO.File]::ReadAllBytes($file)
        $ctx.Response.StatusCode = $status
        $ext = [IO.Path]::GetExtension($file).ToLower()
        $ctx.Response.ContentType = if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' }
        $ctx.Response.ContentLength64 = $bytes.Length
        if ($ctx.Request.HttpMethod -ne 'HEAD') { $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length) }
        } catch { Write-Host $_ } finally { $ctx.Response.Close() }
    }
} finally { $listener.Stop() }
