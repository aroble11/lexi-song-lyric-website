# Create a portable, checked ZIP in a user-selected folder.
param([Parameter(Mandatory=$true)][string]$Destination, [switch]$AllowInsideRepository)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/lyric-evidence.ps1')
Push-Location $PSScriptRoot
$archive = $null
$stream = $null
$outputFile = $null
try {
    $script:EvidenceOpenSsl = Find-EvidenceOpenSsl
    Test-LyricEvidence
    $root = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\','/')
    $target = [IO.Path]::GetFullPath($Destination).TrimEnd('\','/')
    $inside = $target.Equals($root,[StringComparison]::OrdinalIgnoreCase) -or $target.StartsWith($root + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
    if ($inside -and -not $AllowInsideRepository) {
        throw 'Choose a backup folder outside the website, or explicitly use -AllowInsideRepository for a local recovery copy.'
    }
    if ($inside) { Write-Host 'This is an in-repository recovery copy, not an independent backup. A local static server may serve it.' }
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    $name = 'lyric-evidence-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,8) + '.zip'
    $outputFile = Join-Path $target $name
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $stream = [IO.File]::Open($outputFile,[IO.FileMode]::CreateNew)
    $archive = New-Object IO.Compression.ZipArchive($stream,[IO.Compression.ZipArchiveMode]::Create,$true)
    $files = @('songs.js','check-before-publish.ps1','timestamp-songs.ps1','backup-lyric-evidence.ps1','scripts/lyric-evidence.ps1','timestamps/README.txt','EVIDENCE.md','.gitattributes')
    $files += @(Get-EvidenceSongs | ForEach-Object { "songs/$_" })
    $files += @(Get-ChildItem -LiteralPath 'timestamps' -File | Where-Object { $_.Extension -in '.tsr','.pem','.crt' } | ForEach-Object { 'timestamps/' + $_.Name })
    $files += @(Get-ChildItem -LiteralPath 'timestamps/evidence' -Recurse -File | ForEach-Object { $_.FullName.Substring($root.Length+1).Replace('\','/') })
    $expected = @{}
    foreach ($file in $files) {
        $expected[$file] = Get-EvidenceHash $file
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,(Join-Path $root $file),$file,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
    $archive.Dispose(); $archive=$null; $stream.Dispose(); $stream=$null
    # Reopen and hash the uncompressed ZIP entries, without extracting copies.
    $archive = [IO.Compression.ZipFile]::OpenRead($outputFile)
    foreach ($entry in $archive.Entries) {
        $input = $entry.Open(); $sha = [Security.Cryptography.SHA256]::Create()
        try { $actual = ([BitConverter]::ToString($sha.ComputeHash($input))).Replace('-','').ToLowerInvariant() }
        finally { $input.Dispose(); $sha.Dispose() }
        if ($actual -ne $expected[$entry.FullName]) { throw "Backup byte mismatch: $($entry.FullName)" }
    }
    if ($archive.Entries.Count -ne $expected.Count) { throw 'Backup file count mismatch.' }
    $archive.Dispose(); $archive=$null
    Test-LyricEvidence
    $checksum = (Get-EvidenceHash $outputFile) + '  ' + $name
    [IO.File]::WriteAllText($outputFile + '.sha256',$checksum + "`n",(New-Object Text.UTF8Encoding $false))
    Write-Host "Verified backup: $outputFile"
    exit 0
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($outputFile) { Write-Host "Backup was NOT confirmed complete: $outputFile" }
    exit 1
}
finally {
    if ($archive) { $archive.Dispose() }
    if ($stream) { $stream.Dispose() }
    Pop-Location
}
