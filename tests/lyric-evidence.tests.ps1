# Integration tests against real FreeTSA proofs in an isolated disposable fixture.
# No network requests: timestamp transport is replaced by local success/failure fixtures.
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
. (Join-Path $repo 'scripts/lyric-evidence.ps1')
$script:EvidenceOpenSsl = Find-EvidenceOpenSsl
$fixture = Join-Path $repo ('.evidence-test-' + [Guid]::NewGuid().ToString('N'))
$count = 0
function Assert-Test([bool]$Condition,[string]$Message) {
    if (-not $Condition) { throw "ASSERTION FAILED: $Message" }
    $script:count++; Write-Host "PASS: $Message"
}
function Assert-Throws([scriptblock]$Action,[string]$Pattern,[string]$Message) {
    $caught = $null
    try { & $Action | Out-Null } catch { $caught = $_.Exception.Message }
    Assert-Test ($null -ne $caught -and $caught -match $Pattern) $Message
}
New-Item -ItemType Directory -Path $fixture | Out-Null
foreach ($dir in @('songs','timestamps','scripts')) { New-Item -ItemType Directory -Path (Join-Path $fixture $dir) | Out-Null }
Copy-Item -LiteralPath (Join-Path $repo 'songs/01-monsters.txt') -Destination (Join-Path $fixture 'songs/test.txt')
Copy-Item -LiteralPath (Join-Path $repo 'timestamps/01-monsters.tsr') -Destination (Join-Path $fixture 'timestamps/test.tsr')
foreach ($cert in @('cacert.pem','tsa.crt')) { Copy-Item -LiteralPath (Join-Path $repo "timestamps/$cert") -Destination (Join-Path $fixture "timestamps/$cert") }
foreach ($scriptFile in @('check-before-publish.ps1','timestamp-songs.ps1','backup-lyric-evidence.ps1')) { Copy-Item -LiteralPath (Join-Path $repo $scriptFile) -Destination (Join-Path $fixture $scriptFile) }
Copy-Item -LiteralPath (Join-Path $repo 'scripts/lyric-evidence.ps1') -Destination (Join-Path $fixture 'scripts/lyric-evidence.ps1')
Copy-Item -LiteralPath (Join-Path $repo 'timestamps/README.txt') -Destination (Join-Path $fixture 'timestamps/README.txt')
Copy-Item -LiteralPath (Join-Path $repo '.gitattributes') -Destination (Join-Path $fixture '.gitattributes')
Copy-Item -LiteralPath (Join-Path $repo 'EVIDENCE.md') -Destination (Join-Path $fixture 'EVIDENCE.md')
[IO.File]::WriteAllText((Join-Path $fixture 'songs.js'),'const SONGS = ["test.txt"];')
Push-Location $fixture
try {
    function Request-EvidenceTimestamp { throw 'NETWORK SHOULD NEVER BE CALLED IN THIS TEST' }
    [IO.File]::WriteAllText((Join-Path $fixture 'songs.js'),'const SONGS = ["test.txt" "second.txt"];')
    Assert-Throws { Get-EvidenceSongs } 'Invalid song array' 'Malformed song list cannot silently skip evidence'
    [IO.File]::WriteAllText((Join-Path $fixture 'songs.js'),'const SONGS = ["test.txt"];')
    $originalHash = Get-EvidenceHash 'timestamps/test.tsr'
    $songHash = Get-EvidenceHash 'songs/test.txt'
    Update-EvidenceSong 'test.txt' -ArchiveOnly
    $info = Get-VerifiedToken 'timestamps/test.tsr'
    $folder = Get-EvidencePackagePath 'test.txt' $info
    Assert-Test ((Get-EvidenceHash "$folder/lyrics.txt") -eq $songHash) 'Migration preserves exact lyric bytes'
    Assert-Test ((Get-EvidenceHash 'timestamps/test.tsr') -eq $originalHash) 'Migration leaves original proof unchanged'
    $manifestHash = Get-EvidenceHash "$folder/manifest.json"
    Update-EvidenceSong 'test.txt' -ArchiveOnly
    Assert-Test ((Get-EvidenceHash "$folder/manifest.json") -eq $manifestHash) 'Repeated migration does not rewrite packages'
    $before = @(Get-ChildItem -Recurse -File | Get-FileHash | ForEach-Object { $_.Path + $_.Hash })
    & powershell -NoProfile -ExecutionPolicy Bypass -File ./check-before-publish.ps1
    Assert-Test ($LASTEXITCODE -eq 0) 'Check accepts valid current and archived proofs'
    $after = @(Get-ChildItem -Recurse -File | Get-FileHash | ForEach-Object { $_.Path + $_.Hash })
    Assert-Test (($before -join "`n") -ceq ($after -join "`n")) 'Check is read-only'

    [IO.File]::AppendAllText((Join-Path $fixture 'songs/test.txt'),"`nChanged draft")
    Assert-Throws { Update-EvidenceSong 'test.txt' } 'EDITED:' 'Changed lyrics are reported as edited'
    & powershell -NoProfile -ExecutionPolicy Bypass -File ./check-before-publish.ps1
    Assert-Test ($LASTEXITCODE -eq 1) 'Prepublish check exits 1 on changed lyrics'
    & powershell -NoProfile -ExecutionPolicy Bypass -File ./timestamp-songs.ps1
    Assert-Test ($LASTEXITCODE -eq 1) 'Timestamp command exits 1 for unstamped edits'
    function Request-EvidenceTimestamp { throw 'Simulated transport failure' }
    Assert-Throws { Update-EvidenceSong 'test.txt' -Restamp } 'Simulated transport failure' 'Failed request stops promotion'
    Assert-Test ((Get-EvidenceHash 'timestamps/test.tsr') -eq $originalHash) 'Failed request preserves current proof'
    Assert-Test (@(Get-ChildItem timestamps -Filter '.pending-*').Count -eq 0) 'Failed request cleans only its temporary files'

    # Validly signed response for the wrong file must not be promoted.
    function Request-EvidenceTimestamp([string]$Snapshot,[string]$Query,[string]$Reply) {
        Copy-Item -LiteralPath (Join-Path $repo 'timestamps/01-monsters.tsr') -Destination $Reply
    }
    Assert-Throws { Update-EvidenceSong 'test.txt' -Restamp } 'unmatched' 'Wrong-file response is rejected even with a valid signature'
    Assert-Test ((Get-EvidenceHash 'timestamps/test.tsr') -eq $originalHash) 'Wrong-file response preserves current proof'

    # Simulate a successful new response using a second real signed song fixture.
    Copy-Item -LiteralPath (Join-Path $repo 'songs/02-i-was-your-moon.txt') -Destination 'songs/test.txt'
    function Request-EvidenceTimestamp([string]$Snapshot,[string]$Query,[string]$Reply) {
        Copy-Item -LiteralPath (Join-Path $repo 'timestamps/02-i-was-your-moon.tsr') -Destination $Reply
    }
    Update-EvidenceSong 'test.txt' -Restamp
    Assert-Test ((Get-EvidenceHash 'timestamps/test.tsr') -ne $originalHash) 'Verified replacement is promoted'
    Assert-Test ((Get-EvidenceHash "$folder/lyrics.txt") -eq $songHash -and (Get-EvidenceHash "$folder/proof.tsr") -eq $originalHash) 'Old lyric bytes and old proof survive successful restamping'
    Test-LyricEvidence

    # Corrupt archived data without changing the current version.
    [IO.File]::AppendAllText((Join-Path $fixture "$folder/lyrics.txt"),'tamper')
    Assert-Throws { Test-LyricEvidence } 'failed' 'Prepublish check rejects corrupted historical packages'
    Copy-Item -LiteralPath (Join-Path $repo 'songs/01-monsters.txt') -Destination "$folder/lyrics.txt"
    $savedToken = [IO.File]::ReadAllBytes((Join-Path $fixture 'timestamps/test.tsr'))
    [IO.File]::WriteAllText((Join-Path $fixture 'timestamps/test.tsr'),'not a valid token')
    Assert-Throws { Update-EvidenceSong 'test.txt' -Restamp } 'Unreadable timestamp' 'Invalid proof is not mislabeled as an edit'
    [IO.File]::WriteAllBytes((Join-Path $fixture 'timestamps/test.tsr'),$savedToken)
    $certBytes = [IO.File]::ReadAllBytes((Join-Path $fixture 'timestamps/cacert.pem'))
    [IO.File]::WriteAllText((Join-Path $fixture 'timestamps/cacert.pem'),'invalid CA')
    Assert-Throws { Update-EvidenceSong 'test.txt' -Restamp } 'verification failed' 'Certificate errors block restamping'
    [IO.File]::WriteAllBytes((Join-Path $fixture 'timestamps/cacert.pem'),$certBytes)
    Remove-Item -LiteralPath 'timestamps/test.tsr'
    & powershell -NoProfile -ExecutionPolicy Bypass -File ./check-before-publish.ps1
    Assert-Test ($LASTEXITCODE -eq 1) 'Missing proof blocks publishing'
    [IO.File]::WriteAllBytes((Join-Path $fixture 'timestamps/test.tsr'),$savedToken)

    $localBackup = Join-Path $fixture 'evidence'
    & powershell -NoProfile -ExecutionPolicy Bypass -File ./backup-lyric-evidence.ps1 -Destination $localBackup
    Assert-Test ($LASTEXITCODE -eq 1 -and -not (Test-Path -LiteralPath $localBackup)) 'In-repository backup requires explicit opt-in'
    & powershell -NoProfile -ExecutionPolicy Bypass -File ./backup-lyric-evidence.ps1 -Destination $localBackup -AllowInsideRepository
    Assert-Test ($LASTEXITCODE -eq 0) 'Explicit local recovery destination is supported'
    # For the fixture, a sibling under the real repository is outside its own root.
    $backupDir = $fixture + '-backup'
    & powershell -NoProfile -ExecutionPolicy Bypass -File ./backup-lyric-evidence.ps1 -Destination $backupDir
    Assert-Test ($LASTEXITCODE -eq 0) 'Backup ZIP verifies its contents after reopening'
    Assert-Test (@(Get-ChildItem -LiteralPath $backupDir -Filter '*.zip.sha256').Count -eq 1) 'Backup includes a SHA-256 checksum'
    Write-Host "$count assertions passed. Test fixtures: $fixture and $backupDir"
}
finally { Pop-Location }
