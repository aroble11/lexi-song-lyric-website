# Real evidence verification in disposable copies; no network or deployment.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$fixture = Join-Path $root ('.publish-test-' + [Guid]::NewGuid().ToString('N'))
$count = 0
function Assert-Publish([bool]$Condition,[string]$Message) {
    if (-not $Condition) { throw "ASSERTION FAILED: $Message" }
    $script:count++; Write-Host "PASS: $Message"
}
function Run-Preparation([string]$Folder) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $fixture 'prepare-site.ps1') -OutputDirectory $Folder
    $script:prepareExit = $LASTEXITCODE
}
try {
    New-Item -ItemType Directory -Path $fixture | Out-Null
    $public = Get-Content -LiteralPath (Join-Path $root 'publish-files.json') -Raw | ConvertFrom-Json
    $required = $public + @('publish-files.json','prepare-site.ps1','scripts/lyric-evidence.ps1')
    $required += @(Get-ChildItem -LiteralPath (Join-Path $root 'songs') -File | ForEach-Object { 'songs/' + $_.Name })
    $required += @(Get-ChildItem -LiteralPath (Join-Path $root 'timestamps') -Recurse -File | Where-Object { $_.Name -ne '.evidence.lock' } | ForEach-Object { $_.FullName.Substring($root.Length+1) })
    foreach ($file in $required) {
        $target = Join-Path $fixture $file
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath (Join-Path $root $file) -Destination $target
    }
    New-Item -ItemType Directory -Path (Join-Path $fixture 'evidence') | Out-Null
    [IO.File]::WriteAllText((Join-Path $fixture 'evidence/private.txt'),'must not ship')
    Run-Preparation '_site'
    Assert-Publish ($prepareExit -eq 0) 'Valid evidence produces a public package'
    $output = Join-Path $fixture '_site'
    Assert-Publish (-not (Test-Path (Join-Path $output 'evidence')) -and -not (Test-Path (Join-Path $output 'timestamps')) -and -not (Test-Path (Join-Path $output 'prepare-site.ps1'))) 'Backups, proofs, and project scripts stay out of the public package'
    Assert-Publish ((Test-Path (Join-Path $output 'assets/notebook-pressed-rose.webp')) -and (Test-Path (Join-Path $output 'assets/heart-broken.svg'))) 'JavaScript-inserted rose and heart are included'
    $song = 'songs/01-monsters.txt'
    $original = [IO.File]::ReadAllBytes((Join-Path $fixture $song))
    $hash = (Get-FileHash -LiteralPath (Join-Path $fixture $song)).Hash
    Assert-Publish ((Get-FileHash -LiteralPath (Join-Path $output $song)).Hash -eq $hash) 'Packaged lyrics preserve exact stamped bytes'
    Run-Preparation '_site'
    Assert-Publish ($prepareExit -eq 1 -and (Get-FileHash -LiteralPath (Join-Path $output $song)).Hash -eq $hash) 'Existing output cannot be overwritten'
    $manifestPath = Join-Path $fixture 'publish-files.json'
    $manifest = [IO.File]::ReadAllText($manifestPath)
    @($public | Where-Object { $_ -ne 'assets/heart-broken.svg' }) | ConvertTo-Json | Set-Content -LiteralPath $manifestPath
    Run-Preparation 'missing-art'
    Assert-Publish ($prepareExit -eq 1 -and -not (Test-Path (Join-Path $fixture 'missing-art'))) 'Missing dynamic artwork blocks packaging'
    [IO.File]::WriteAllText($manifestPath,$manifest)
    [IO.File]::AppendAllText((Join-Path $fixture $song),'changed')
    Run-Preparation 'edited'
    Assert-Publish ($prepareExit -eq 1 -and -not (Test-Path (Join-Path $fixture 'edited'))) 'Unstamped edits block packaging before output is created'
    [IO.File]::WriteAllBytes((Join-Path $fixture $song),$original)
    ($public + 'evidence/private.txt') | ConvertTo-Json | Set-Content -LiteralPath $manifestPath
    Run-Preparation 'private-entry'
    Assert-Publish ($prepareExit -eq 1 -and -not (Test-Path (Join-Path $fixture 'private-entry'))) 'Private paths cannot be added to the public manifest'
    [IO.File]::WriteAllText($manifestPath,$manifest)
    $archivedProof = Get-ChildItem -LiteralPath (Join-Path $fixture 'timestamps/evidence') -Recurse -Filter proof.tsr | Select-Object -First 1
    [IO.File]::WriteAllText($archivedProof.FullName,'damaged')
    Run-Preparation 'bad-proof'
    Assert-Publish ($prepareExit -eq 1 -and -not (Test-Path (Join-Path $fixture 'bad-proof'))) 'Damaged archive proof blocks packaging'
    Write-Host "$count publishing assertions passed. No production files were modified."
}
finally {
    if (Test-Path -LiteralPath $fixture) {
        $resolved = (Resolve-Path -LiteralPath $fixture).Path
        if ((Split-Path -Parent $resolved) -ne $root -or (Split-Path -Leaf $resolved) -notmatch '^\.publish-test-[0-9a-f]{32}$') { throw 'Unsafe test cleanup path.' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
# Expected failing child processes must not leak exit code 1 into CI's wrapper.
exit 0
