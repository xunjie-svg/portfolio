param(
    [int]$Port = 5500
)

$RootDir = $PSScriptRoot

$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Live server running at $prefix (Ctrl+C to stop)"

$mimeMap = @{
    ".html"  = "text/html; charset=utf-8"
    ".htm"   = "text/html; charset=utf-8"
    ".css"   = "text/css; charset=utf-8"
    ".js"    = "application/javascript; charset=utf-8"
    ".json"  = "application/json; charset=utf-8"
    ".svg"   = "image/svg+xml"
    ".png"   = "image/png"
    ".jpg"   = "image/jpeg"
    ".jpeg"  = "image/jpeg"
    ".gif"   = "image/gif"
    ".ico"   = "image/x-icon"
    ".woff"  = "font/woff"
    ".woff2" = "font/woff2"
    ".txt"   = "text/plain; charset=utf-8"
    ".map"   = "application/json"
}

$watchExtensions = @(".html", ".css", ".js")

function Get-WatchStamp {
    $files = Get-ChildItem -Path $RootDir -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $watchExtensions -contains $_.Extension -and $_.FullName -notmatch '\\\.claude\\' -and $_.Name -ne 'serve.ps1' }
    if (-not $files) { return 0 }
    ($files | Measure-Object -Property LastWriteTimeUtc -Maximum).Maximum.Ticks
}

$reloadScript = @'
<script>
(function(){
  var last = null;
  setInterval(function(){
    fetch('/__livereload').then(function(r){ return r.json(); }).then(function(d){
      if (last === null) { last = d.stamp; return; }
      if (d.stamp !== last) { location.reload(); }
    }).catch(function(){});
  }, 1000);
})();
</script>
'@

$fullRoot = (Resolve-Path $RootDir).Path

while ($listener.IsListening) {
    $context = $null
    try {
        $context = $listener.GetContext()
    } catch {
        break
    }
    $request = $context.Request
    $response = $context.Response
    try {
        $path = $request.Url.AbsolutePath

        $response.Headers.Add("Cache-Control", "no-store, no-cache, must-revalidate")
        $response.Headers.Add("Pragma", "no-cache")

        if ($path -eq "/__livereload") {
            $stamp = Get-WatchStamp
            $json = "{`"stamp`":$stamp}"
            $buf = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buf.Length
            $response.OutputStream.Write($buf, 0, $buf.Length)
            $response.OutputStream.Close()
            continue
        }

        if ($path -eq "/") { $path = "/index.html" }
        $relPath = $path.TrimStart("/") -replace "/", "\"
        $filePath = Join-Path $RootDir $relPath

        $resolvedFile = $null
        if (Test-Path -LiteralPath $filePath -PathType Leaf) {
            $resolvedFile = (Resolve-Path -LiteralPath $filePath).Path
        }

        if (-not $resolvedFile -or -not $resolvedFile.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $response.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $response.ContentType = "text/plain"
            $response.ContentLength64 = $msg.Length
            $response.OutputStream.Write($msg, 0, $msg.Length)
            $response.OutputStream.Close()
            continue
        }

        $ext = [System.IO.Path]::GetExtension($resolvedFile).ToLower()
        $mime = $mimeMap[$ext]
        if (-not $mime) { $mime = "application/octet-stream" }

        if ($ext -eq ".html" -or $ext -eq ".htm") {
            $content = Get-Content -LiteralPath $resolvedFile -Raw -Encoding UTF8
            if ($content -match "</body>") {
                $content = $content -replace "</body>", "$reloadScript</body>"
            } else {
                $content += $reloadScript
            }
            $buf = [System.Text.Encoding]::UTF8.GetBytes($content)
        } else {
            $buf = [System.IO.File]::ReadAllBytes($resolvedFile)
        }

        $response.ContentType = $mime
        $response.ContentLength64 = $buf.Length
        $response.OutputStream.Write($buf, 0, $buf.Length)
        $response.OutputStream.Close()
    } catch {
        try {
            $response.StatusCode = 500
            $response.OutputStream.Close()
        } catch {}
    }
}
