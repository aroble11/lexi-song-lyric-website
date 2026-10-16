# Build a fresh, allowlisted Pages artifact only after evidence verification.
param([string]$OutputDirectory = '_site')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/lyric-evidence.ps1')
Push-Location $PSScriptRoot
try {
    $root = [IO.Path]::GetFullPath($PSScriptRoot)
    $output = [IO.Path]::GetFullPath((Join-Path $root $OutputDirectory))
    if (-not $output.StartsWith($root + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Output must be a new folder inside this project.'
    }
    if (Test-Path -LiteralPath $output) { throw 'Output already exists. Choose a fresh output folder; existing files will not be overwritten.' }
    $ancestor = Split-Path -Parent $output
    while ($ancestor -and $ancestor -ne $root) {
        if ((Test-Path -LiteralPath $ancestor) -and ((Get-Item -LiteralPath $ancestor).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'Output cannot pass through a linked directory.'
        }
        $ancestor = Split-Path -Parent $ancestor
    }
    $script:EvidenceOpenSsl = Find-EvidenceOpenSsl
    Test-LyricEvidence
    $songs = @(Get-EvidenceSongs)
    $files = Get-Content -LiteralPath 'publish-files.json' -Raw | ConvertFrom-Json
    if (@($files | Sort-Object -Unique).Count -ne $files.Count) { throw 'Duplicate publishing entry.' }
    foreach ($file in $files) {
        if ($file -isnot [string] -or $file -match '(^|/)\.\.?(/|$)|\\|:' -or
            $file -notmatch '^(index\.html|styles\.css|main\.js|songs\.js|assets/[A-Za-z0-9._/-]+\.(webp|svg|png|jpg)|fonts/[A-Za-z0-9._/-]+\.(woff2|ttf|otf)|fonts/[A-Za-z0-9._/-]+/OFL\.txt)$') {
            throw "Non-public or invalid publishing entry: $file"
        }
    }
    foreach ($required in @('index.html','styles.css','main.js','songs.js')) {
        if ($required -cnotin $files) { throw "Missing publishing entry: $required" }
    }
    # Catch forgotten artwork, including images inserted by JavaScript.
    foreach ($source in @('index.html','styles.css','main.js')) {
        $text = Get-Content -LiteralPath $source -Raw
        foreach ($match in [regex]::Matches($text, '(?:assets|fonts)/[A-Za-z0-9_./-]+\.(?:webp|svg|png|jpg|woff2|ttf|otf)\b')) {
            if ($match.Value -cnotin $files) { throw "Referenced resource is not approved for publishing: $($match.Value)" }
        }
    }
    $files += @($songs | ForEach-Object { "songs/$_" })
    $hashes = @{}
    foreach ($file in $files) {
        $sourcePath = Join-Path $root $file
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Missing public file: $file" }
        $part = $sourcePath
        while ($part -ne $root) {
            if ((Get-Item -LiteralPath $part).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked public path is not allowed: $file" }
            $part = Split-Path -Parent $part
        }
        $hashes[$file] = Get-EvidenceHash $sourcePath
    }
    New-Item -ItemType Directory -Path $output | Out-Null
    foreach ($file in $files) {
        $destination = Join-Path $output $file
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
        Copy-Item -LiteralPath (Join-Path $root $file) -Destination $destination
        if ((Get-EvidenceHash $destination) -ne $hashes[$file]) { throw "Public copy changed: $file" }
    }
    # Validate the actual copied song bytes, not just the original source tree.
    foreach ($song in $songs) {
        $token = 'timestamps/' + [IO.Path]::GetFileNameWithoutExtension($song) + '.tsr'
        $info = Get-VerifiedToken $token
        if ((Get-EvidenceHash (Join-Path $output "songs/$song")) -ne $info.Hash) { throw "Packaged song does not match its proof: $song" }
    }
    foreach ($file in $files) {
        if ((Get-EvidenceHash (Join-Path $root $file)) -ne $hashes[$file]) { throw "Source changed during preparation: $file" }
    }
    [IO.File]::WriteAllText((Join-Path $output '.nojekyll'),'')
    $actual = @(Get-ChildItem -LiteralPath $output -Recurse -Force -File | ForEach-Object { $_.FullName.Substring($output.Length+1).Replace('\','/') })
    $expected = @($files) + '.nojekyll'
    if (Compare-Object ($expected | Sort-Object) ($actual | Sort-Object)) { throw 'Unexpected files in publishing output.' }
    Write-Host "READY: $($actual.Count) verified public files in $output"
    Write-Host 'This only prepares local files. Nothing was uploaded or published.'
    exit 0
}
catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
finally { Pop-Location }
