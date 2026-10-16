# Offline, read-only validation. A failing check exits 1; nothing is stamped.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/lyric-evidence.ps1')
Push-Location $PSScriptRoot
try {
    $script:EvidenceOpenSsl = Find-EvidenceOpenSsl
    Test-LyricEvidence
    exit 0
}
catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
finally { Pop-Location }
