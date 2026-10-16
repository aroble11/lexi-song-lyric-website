<#
Create complete lyric evidence packages and request timestamps only when needed.
  .\timestamp-songs.ps1              Archive valid proofs; stamp missing proofs.
  .\timestamp-songs.ps1 -ArchiveOnly  Offline migration; never request new stamps.
  .\timestamp-songs.ps1 -Restamp      Stamp reviewed changes, retaining old packages.
Only SHA-256 request data is sent to FreeTSA, never the lyrics themselves.
Any missing, outdated, invalid, or unarchivable proof returns exit code 1.
#>
param([switch]$Restamp, [switch]$ArchiveOnly)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/lyric-evidence.ps1')
Push-Location $PSScriptRoot
$writerLock = $null
try {
    if ($Restamp -and $ArchiveOnly) { throw 'Choose -Restamp or -ArchiveOnly, not both.' }
    $script:EvidenceOpenSsl = Find-EvidenceOpenSsl
    foreach ($cert in @('timestamps/cacert.pem','timestamps/tsa.crt')) {
        if (-not (Test-Path -LiteralPath $cert)) { throw "Missing trusted certificate $cert. Restore it from your verified backup; it will not be silently replaced." }
    }
    $lockPath = Join-Path $PSScriptRoot 'timestamps/.evidence.lock'
    $writerLock = [IO.File]::Open($lockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $failed = 0
    foreach ($song in @(Get-EvidenceSongs)) {
        try { Update-EvidenceSong $song -Restamp:$Restamp -ArchiveOnly:$ArchiveOnly }
        catch { $failed++; Write-Host "[FAIL] $song - $($_.Exception.Message)" -ForegroundColor Red }
    }
    if ($failed) { throw "$failed song(s) need attention. Existing valid proof packages were retained." }
    Test-LyricEvidence
    Write-Host 'Commit the byte-preservation rules, songs, current proofs, and evidence packages together. Back them up before publishing.'
    exit 0
}
catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
finally { if ($writerLock) { $writerLock.Dispose() }; Pop-Location }
