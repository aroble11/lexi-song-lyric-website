# Shared evidence routines. Compatible with Windows PowerShell 5.1 and PowerShell 7.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-EvidenceOpenSsl {
    $git = Get-Command git -ErrorAction SilentlyContinue
    $candidates = @()
    if ($git) {
        $base = Split-Path -Parent (Split-Path -Parent $git.Source)
        # Prefer the native Windows executable over the MSYS executable.
        $candidates += (Join-Path $base 'mingw64/bin/openssl.exe')
        $candidates += (Join-Path $base 'usr/bin/openssl.exe')
    }
    $command = Get-Command openssl -ErrorAction SilentlyContinue
    if ($command) { $candidates += $command.Source }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    throw 'OpenSSL not found. Install Git for Windows or put OpenSSL on PATH.'
}

function Invoke-EvidenceOpenSsl([string[]]$Arguments) {
    # Native stderr is diagnostic output, not PowerShell's success/failure signal.
    $ErrorActionPreference = 'Continue'
    $output = & $script:EvidenceOpenSsl @Arguments 2>&1
    $code = $LASTEXITCODE
    [pscustomobject]@{ Code = $code; Text = ($output | Out-String) }
}

function Get-EvidenceHash([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-EvidenceSongs {
    $source = [IO.File]::ReadAllText((Join-Path (Get-Location).Path 'songs.js'))
    $source = [regex]::Replace($source, '(?s)/\*.*?\*/|(?m)//[^\r\n]*', '')
    $match = [regex]::Match($source, '(?s)^\s*const\s+SONGS\s*=\s*\[(.*?)\]\s*;?\s*$')
    if (-not $match.Success) { throw 'Unsupported songs.js syntax: expected one const SONGS array.' }
    $body = $match.Groups[1].Value
    $filenamePattern = '"[A-Za-z0-9][A-Za-z0-9._-]*\.txt"'
    if ($body -notmatch ('(?s)^\s*' + $filenamePattern + '\s*(?:,\s*' + $filenamePattern + '\s*)*,?\s*$')) {
        throw 'Invalid song array: separate each quoted filename with a comma.'
    }
    $strings = [regex]::Matches($body, '"([A-Za-z0-9][A-Za-z0-9._-]*\.txt)"')
    $remainder = [regex]::Replace($body, '"([A-Za-z0-9][A-Za-z0-9._-]*\.txt)"', '')
    if ($remainder -match '[^\s,]' -or $strings.Count -eq 0) { throw 'Song filenames must be simple quoted .txt names without paths or spaces.' }
    $files = @($strings | ForEach-Object { $_.Groups[1].Value })
    if (@($files | Sort-Object -Unique).Count -ne $files.Count) { throw 'Duplicate song filename in songs.js.' }
    return $files
}

function Get-VerifiedToken([string]$Token, [string]$Ca = 'timestamps/cacert.pem', [string]$Signer = 'timestamps/tsa.crt') {
    foreach ($path in @($Token,$Ca,$Signer)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing proof or certificate: $path" }
    }
    $reply = Invoke-EvidenceOpenSsl @('ts','-reply','-in',$Token,'-text')
    if ($reply.Code -ne 0) { throw "Unreadable timestamp: $Token. $($reply.Text)" }
    if ($reply.Text -notmatch 'Hash Algorithm: sha256\b') { throw "Unsupported timestamp hash in $Token; expected SHA-256." }
    $block = [regex]::Match($reply.Text, '(?s)Message data:\s*(.*?)Serial number:').Groups[1].Value
    $hash = ''
    foreach ($line in ($block -split '\r?\n')) {
        if ($line -match '^\s*[0-9a-fA-F]+ - ((?:[0-9a-fA-F]{2}[ -]){15}[0-9a-fA-F]{2})') {
            $hash += ($Matches[1] -replace '[ -]','').ToLowerInvariant()
        }
    }
    if ($hash -notmatch '^[a-f0-9]{64}$') { throw "Cannot read SHA-256 imprint in $Token." }
    # Verify against the signed imprint first. A failed signature/chain is never
    # mislabeled as a changed lyric file, and is never fixed by auto-restamping.
    $verification = Invoke-EvidenceOpenSsl @('ts','-verify','-digest',$hash,'-in',$Token,'-CAfile',$Ca,'-untrusted',$Signer)
    if ($verification.Code -ne 0) { throw "Proof verification failed: $Token. $($verification.Text)" }
    $dateMatch = [regex]::Match($reply.Text, '(?m)^Time stamp:\s*(.+?)\s*$')
    $dateText = ($dateMatch.Groups[1].Value.Trim() -replace '\s+',' ')
    $formats = [string[]]@("MMM d HH:mm:ss yyyy 'GMT'", "MMM d HH:mm:ss.FFFFFFF yyyy 'GMT'")
    $date = [DateTimeOffset]::ParseExact($dateText,$formats,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal)
    [pscustomobject]@{ Hash = $hash; Utc = $date.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'); TokenHash = (Get-EvidenceHash $Token) }
}

function Get-EvidencePackagePath([string]$Song, $TokenInfo) {
    $slug = [IO.Path]::GetFileNameWithoutExtension($Song)
    $stamp = $TokenInfo.Utc -replace '[-:]',''
    "timestamps/evidence/$slug/$stamp-$($TokenInfo.Hash.Substring(0,16))-$($TokenInfo.TokenHash.Substring(0,8))"
}

function Assert-EvidencePackage([string]$Folder, [string]$ExpectedSong = '') {
    $manifestPath = Join-Path $Folder 'manifest.json'
    $meta = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($meta.schemaVersion -ne 1) { throw "Unsupported evidence manifest: $Folder" }
    if ($ExpectedSong -and $meta.songFile -cne $ExpectedSong) { throw "Song identity mismatch: $Folder" }
    foreach ($name in @('lyrics.txt','proof.tsr','cacert.pem','tsa.crt')) {
        $property = $meta.files.PSObject.Properties[$name]
        if (-not $property -or (Get-EvidenceHash (Join-Path $Folder $name)) -cne $property.Value) {
            throw "Evidence file fingerprint mismatch: $Folder/$name"
        }
    }
    # Package metadata cannot introduce an arbitrary new trust anchor.
    if ((Get-EvidenceHash (Join-Path $Folder 'cacert.pem')) -ne (Get-EvidenceHash 'timestamps/cacert.pem')) {
        throw "Archived CA differs from the project's trusted CA. Review it explicitly: $Folder"
    }
    $info = Get-VerifiedToken (Join-Path $Folder 'proof.tsr') (Join-Path $Folder 'cacert.pem') (Join-Path $Folder 'tsa.crt')
    if ($info.Hash -ne (Get-EvidenceHash (Join-Path $Folder 'lyrics.txt')) -or $meta.timestampUtc -cne $info.Utc) {
        throw "Signed date or lyric bytes do not match evidence manifest: $Folder"
    }
    return $info
}

function Save-EvidencePackage([string]$Song, [string]$Lyrics, [string]$Token) {
    $info = Get-VerifiedToken $Token
    if ((Get-EvidenceHash $Lyrics) -ne $info.Hash) { throw "Cannot archive unmatched lyric bytes for $Song." }
    $destination = Get-EvidencePackagePath $Song $info
    if (Test-Path -LiteralPath $destination) {
        $checked = Assert-EvidencePackage $destination $Song
        return $destination
    }
    $parent = Split-Path -Parent $destination
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $pending = Join-Path $parent ('.pending-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $pending | Out-Null
    try {
        Copy-Item -LiteralPath $Lyrics -Destination (Join-Path $pending 'lyrics.txt')
        Copy-Item -LiteralPath $Token -Destination (Join-Path $pending 'proof.tsr')
        Copy-Item -LiteralPath 'timestamps/cacert.pem' -Destination (Join-Path $pending 'cacert.pem')
        Copy-Item -LiteralPath 'timestamps/tsa.crt' -Destination (Join-Path $pending 'tsa.crt')
        $hashes = [ordered]@{}
        foreach ($name in @('lyrics.txt','proof.tsr','cacert.pem','tsa.crt')) { $hashes[$name] = Get-EvidenceHash (Join-Path $pending $name) }
        $titleMatch = [regex]::Match([IO.File]::ReadAllText((Join-Path (Get-Location).Path $Lyrics)), '(?m)^Title:\s*(.+?)\s*$')
        $meta = [ordered]@{ schemaVersion=1; songFile=$Song; title=$titleMatch.Groups[1].Value; timestampUtc=$info.Utc; packagedUtc=[DateTimeOffset]::UtcNow.ToString('o'); files=$hashes; meaning='The timestamp proves existence of these exact bytes by its signed date, not authorship.' }
        $json = $meta | ConvertTo-Json -Depth 5
        [IO.File]::WriteAllText((Join-Path (Get-Location).Path "$pending/manifest.json"), $json, (New-Object Text.UTF8Encoding $false))
        $checked = Assert-EvidencePackage $pending $Song
        Move-Item -LiteralPath $pending -Destination $destination
        return $destination
    }
    finally {
        # Never recursively delete a computed tree: only this run's known files.
        if (Test-Path -LiteralPath $pending) {
            foreach ($name in @('lyrics.txt','proof.tsr','cacert.pem','tsa.crt','manifest.json')) {
                $file = Join-Path $pending $name
                if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file }
            }
            [IO.Directory]::Delete((Join-Path (Get-Location).Path $pending), $false)
        }
    }
}

function Assert-OldVersionArchived([string]$Song, [string]$Token) {
    $info = Get-VerifiedToken $Token
    $folder = Get-EvidencePackagePath $Song $info
    if (-not (Test-Path -LiteralPath $folder)) {
        throw "Old lyric snapshot is missing for $Song. Recover its exact original bytes before restamping; the current proof has been kept."
    }
    $checked = Assert-EvidencePackage $folder $Song
}

function Request-EvidenceTimestamp([string]$Snapshot, [string]$Query, [string]$Reply) {
    $queryResult = Invoke-EvidenceOpenSsl @('ts','-query','-data',$Snapshot,'-sha256','-cert','-out',$Query)
    if ($queryResult.Code -ne 0) { throw "Timestamp request failed. $($queryResult.Text)" }
    & curl.exe --fail --silent --show-error --connect-timeout 15 --max-time 90 -H 'Content-Type: application/timestamp-query' --data-binary "@$Query" -o $Reply 'https://freetsa.org/tsr'
    if ($LASTEXITCODE -ne 0) { throw 'FreeTSA request failed; existing proof was not replaced.' }
    # Check the request nonce as well as the imprint and signature.
    $verified = Invoke-EvidenceOpenSsl @('ts','-verify','-queryfile',$Query,'-in',$Reply,'-CAfile','timestamps/cacert.pem','-untrusted','timestamps/tsa.crt')
    if ($verified.Code -ne 0) { throw "Timestamp reply failed request verification. $($verified.Text)" }
    $info = Get-VerifiedToken $Reply
    if ($info.Hash -ne (Get-EvidenceHash $Snapshot)) { throw 'Timestamp reply does not match the captured lyrics.' }
}

function Update-EvidenceSong([string]$Song, [switch]$Restamp, [switch]$ArchiveOnly) {
    $lyrics = "songs/$Song"
    if (-not (Test-Path -LiteralPath $lyrics -PathType Leaf)) { throw "Missing song: $lyrics" }
    $token = 'timestamps/' + [IO.Path]::GetFileNameWithoutExtension($Song) + '.tsr'
    $oldTokenHash = $null
    if (Test-Path -LiteralPath $token) {
        $oldInfo = Get-VerifiedToken $token
        $oldTokenHash = $oldInfo.TokenHash
        if ((Get-EvidenceHash $lyrics) -eq $oldInfo.Hash) {
            $package = Save-EvidencePackage $Song $lyrics $token
            Write-Host "[OK] $Song - verified, exact snapshot saved"
            return
        }
        if (-not $Restamp -or $ArchiveOnly) { throw "EDITED: $Song differs from its signed proof. Use -Restamp after reviewing your changes." }
        Assert-OldVersionArchived $Song $token
    }
    elseif ($ArchiveOnly) { throw "MISSING PROOF: $Song; ArchiveOnly never requests new timestamps." }

    $id = [Guid]::NewGuid().ToString('N')
    $snapshot = "timestamps/.pending-$id.txt"
    $query = "timestamps/.pending-$id.tsq"
    $reply = "timestamps/.pending-$id.tsr"
    $replacedBackup = "timestamps/.pending-$id.previous.tsr"
    try {
        Copy-Item -LiteralPath $lyrics -Destination $snapshot
        $snapshotHash = Get-EvidenceHash $snapshot
        Request-EvidenceTimestamp $snapshot $query $reply
        if ((Get-EvidenceHash $lyrics) -ne $snapshotHash) { throw 'Lyrics changed during timestamping; nothing was promoted.' }
        if ($oldTokenHash -and (Get-EvidenceHash $token) -ne $oldTokenHash) { throw 'Existing proof changed during timestamping; nothing was promoted.' }
        $package = Save-EvidencePackage $Song $snapshot $reply
        # Validate once more immediately before promotion. The complete previous
        # package already exists, and File.Replace never removes it.
        if ((Get-EvidenceHash $lyrics) -ne $snapshotHash) { throw 'Lyrics changed while archiving; nothing was promoted.' }
        if ($oldTokenHash -and (Get-EvidenceHash $token) -ne $oldTokenHash) { throw 'Existing proof changed while archiving; nothing was promoted.' }
        $absoluteReply = Join-Path (Get-Location).Path $reply
        $absoluteToken = Join-Path (Get-Location).Path $token
        if (Test-Path -LiteralPath $token) { [IO.File]::Replace($absoluteReply,$absoluteToken,(Join-Path (Get-Location).Path $replacedBackup)) }
        else { [IO.File]::Move($absoluteReply,$absoluteToken) }
        Write-Host "[STAMPED] $Song - verified new proof and complete version package"
    }
    finally {
        foreach ($file in @($snapshot,$query,$reply,$replacedBackup)) {
            if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file }
        }
    }
}

function Test-LyricEvidence {
    $failed = 0
    foreach ($song in @(Get-EvidenceSongs)) {
        try {
            $lyrics = "songs/$song"
            $token = 'timestamps/' + [IO.Path]::GetFileNameWithoutExtension($song) + '.tsr'
            $info = Get-VerifiedToken $token
            if ((Get-EvidenceHash $lyrics) -ne $info.Hash) { throw 'EDITED: current bytes do not match the signed fingerprint.' }
            $package = Get-EvidencePackagePath $song $info
            $checked = Assert-EvidencePackage $package $song
            Write-Host "[OK] $song - $($info.Utc)"
        } catch { $failed++; Write-Host "[FAIL] $song - $($_.Exception.Message)" -ForegroundColor Red }
    }
    # Every historic version matters, including versions no longer on the site.
    $archive = 'timestamps/evidence'
    if (Test-Path -LiteralPath $archive) {
        foreach ($songDir in @(Get-ChildItem -LiteralPath $archive -Directory)) {
            foreach ($version in @(Get-ChildItem -LiteralPath $songDir.FullName -Directory)) {
                try {
                    if ($version.Name.StartsWith('.pending-')) { throw 'Incomplete package from an interrupted run; review before publishing.' }
                    $relative = "timestamps/evidence/$($songDir.Name)/$($version.Name)"
                    $checked = Assert-EvidencePackage $relative ($songDir.Name + '.txt')
                } catch { $failed++; Write-Host "[FAIL] Archive $($version.Name): $($_.Exception.Message)" -ForegroundColor Red }
            }
        }
    }
    if ($failed) { throw "$failed evidence check(s) failed. Do not publish." }
    Write-Host 'PASS: current songs and archived evidence verify. No files were changed.'
}
