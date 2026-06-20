<#
=============================================================================
 timestamp-songs.ps1 - GET TRUSTED TIMESTAMPS FOR YOUR SONGS
=============================================================================
 WHAT THIS DOES, IN PLAIN WORDS:
   For every song listed in songs.js, this script asks FreeTSA.org
   (a free, independent timestamping authority) to cryptographically
   certify "this exact file existed at this exact moment." The proof
   comes back as a small .tsr file saved into the timestamps/ folder.

   Your lyrics are NEVER sent anywhere - only a SHA-256 "fingerprint"
   (hash) of each file goes to FreeTSA. The fingerprint can't be
   reversed back into the lyrics.

 HOW TO RUN IT:
   1. Open PowerShell in this folder
      (in File Explorer: Shift + right-click the folder ->
       "Open PowerShell window here")
   2. Type:   .\timestamp-songs.ps1
      (If Windows blocks it, run instead:
       powershell -ExecutionPolicy Bypass -File .\timestamp-songs.ps1 )

 WHAT IT NEEDS:
   - OpenSSL. You almost certainly already have it: it ships with
     Git for Windows. The script finds it automatically.
   - An internet connection (to reach freetsa.org).

 THE GOLDEN RULE:
   A timestamp matches the file's EXACT bytes. If you edit a song
   after stamping it, the old proof no longer matches the new text.
   That's expected! Re-run this script with -Restamp to stamp the
   new version; the old token is kept (renamed with a date) because
   it still proves the OLD version existed on its date.

 OPTIONS:
   .\timestamp-songs.ps1            stamps any song without a token,
                                    reports (but keeps) outdated ones
   .\timestamp-songs.ps1 -Restamp   also re-stamps edited songs
=============================================================================
#>

param(
    # Add -Restamp when running the script to re-stamp songs that
    # were edited after their last timestamp.
    [switch]$Restamp
)

# Stop on unexpected errors instead of plowing ahead.
$ErrorActionPreference = "Stop"

# Older Windows PowerShell defaults to outdated TLS; freetsa.org
# (sensibly) requires modern TLS 1.2.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# The folder this script file lives in (= the site folder).
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# -----------------------------------------------------------------
# STEP 1: find OpenSSL (no PATH setup required)
# -----------------------------------------------------------------
function Find-OpenSsl {
    # First choice: it's already on the PATH.
    $cmd = Get-Command "openssl" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # Next: Git for Windows includes OpenSSL. If git itself is on
    # the PATH, look inside its install folder (works no matter
    # which drive Git was installed to).
    $git = Get-Command "git" -ErrorAction SilentlyContinue
    if ($git) {
        # git.exe lives at <install>\cmd\git.exe, so go up two levels
        $gitRoot = Split-Path -Parent (Split-Path -Parent $git.Source)
        foreach ($sub in @("usr\bin\openssl.exe", "mingw64\bin\openssl.exe")) {
            $path = Join-Path $gitRoot $sub
            if (Test-Path $path) { return $path }
        }
    }

    # Last resort: the usual install locations on the C: drive.
    $candidates = @(
        "C:\Program Files\Git\usr\bin\openssl.exe",
        "C:\Program Files\Git\mingw64\bin\openssl.exe",
        "C:\Program Files (x86)\Git\usr\bin\openssl.exe",
        "$env:LOCALAPPDATA\Programs\Git\usr\bin\openssl.exe"
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) { return $path }
    }
    return $null
}

$openssl = Find-OpenSsl
if (-not $openssl) {
    Write-Host ""
    Write-Host "Couldn't find OpenSSL on this computer." -ForegroundColor Red
    Write-Host "Easiest fix: install Git for Windows (https://git-scm.com/download/win)"
    Write-Host "- it includes OpenSSL, and this script will then find it automatically."
    exit 1
}
Write-Host "Using OpenSSL at: $openssl" -ForegroundColor DarkGray

# Helper: returns $true if an existing token still matches the file
# (i.e. the song has NOT been edited since it was stamped).
function Test-TokenMatches([string]$songPath, [string]$tokenPath) {
    # OpenSSL prints harmless progress notes to its "error" stream
    # even when everything works. Inside this function we relax
    # PowerShell's error handling so that chatter is ignored, and
    # trust the exit code - the real success/failure signal.
    $ErrorActionPreference = "Continue"
    & $openssl ts -verify -data $songPath -in $tokenPath `
        -CAfile "timestamps\cacert.pem" -untrusted "timestamps\tsa.crt" 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

# Helper: requests a fresh timestamp for one file from FreeTSA.
function New-Timestamp([string]$songPath, [string]$tokenPath) {
    # The request file is temporary; it lives in timestamps\ only
    # while this function runs.
    $tsqPath = "timestamps\.pending-request.tsq"
    try {
        # Same as in Test-TokenMatches: ignore OpenSSL's harmless
        # stderr chatter and judge success by exit codes only.
        $ErrorActionPreference = "Continue"

        # 1) Build the request: a SHA-256 fingerprint of the file.
        #    (-cert asks FreeTSA to include its certificate in the
        #    reply, which makes later verification self-contained.)
        & $openssl ts -query -data $songPath -sha256 -cert -out $tsqPath 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "OpenSSL could not create the request." }

        # 2) Send the fingerprint to FreeTSA; the signed proof comes
        #    back. curl ships with Windows 10/11 and handles this
        #    binary upload/download reliably.
        & curl.exe -s -S `
            -H "Content-Type: application/timestamp-query" `
            --data-binary "@$tsqPath" `
            -o $tokenPath `
            https://freetsa.org/tsr
        if ($LASTEXITCODE -ne 0) { throw "Could not reach freetsa.org - check your internet connection." }

        # 3) Immediately verify what we got, so a bad reply never
        #    sits in the folder looking like real proof.
        if (-not (Test-TokenMatches $songPath $tokenPath)) {
            Remove-Item $tokenPath -ErrorAction SilentlyContinue
            throw "FreeTSA's reply did not verify - token discarded."
        }
    }
    finally {
        Remove-Item $tsqPath -ErrorAction SilentlyContinue
    }
}

# -----------------------------------------------------------------
# Work from inside the site folder, using short relative paths like
# "songs\title.txt". This matters: OpenSSL 3 cannot read file paths
# that contain spaces (it parses them as URLs), and folders like
# "My Documents" would otherwise break everything.
# Push-Location remembers where you were; the finally block at the
# bottom always puts you back there.
# -----------------------------------------------------------------
Push-Location $root
try {

    # -------------------------------------------------------------
    # STEP 2: make sure FreeTSA's public certificates are downloaded.
    # These are needed to VERIFY timestamps (yours and anyone
    # else's). They're public files, identical for everyone - safe
    # to fetch once and keep in the repo.
    # -------------------------------------------------------------
    if (-not (Test-Path "timestamps")) {
        New-Item -ItemType Directory -Path "timestamps" | Out-Null
    }
    if (-not (Test-Path "timestamps\cacert.pem")) {
        Write-Host "Downloading FreeTSA CA certificate (one-time setup)..."
        Invoke-WebRequest -Uri "https://freetsa.org/files/cacert.pem" `
            -OutFile "timestamps\cacert.pem" -UseBasicParsing
    }
    if (-not (Test-Path "timestamps\tsa.crt")) {
        Write-Host "Downloading FreeTSA signing certificate (one-time setup)..."
        Invoke-WebRequest -Uri "https://freetsa.org/files/tsa.crt" `
            -OutFile "timestamps\tsa.crt" -UseBasicParsing
    }

    # -------------------------------------------------------------
    # STEP 3: read the song list out of songs.js.
    # We just pick out every "something.txt" between quotes - the
    # same names the website itself uses.
    # -------------------------------------------------------------
    $songsJs = Get-Content "songs.js" -Raw
    $songFiles = [regex]::Matches($songsJs, '"([^"]+\.txt)"') | ForEach-Object { $_.Groups[1].Value }

    if ($songFiles.Count -eq 0) {
        Write-Host "No songs found in songs.js - nothing to stamp." -ForegroundColor Yellow
        exit 0
    }
    Write-Host "Found $($songFiles.Count) song(s) in songs.js`n"

    # -------------------------------------------------------------
    # STEP 4: walk through every song and stamp / check it.
    # -------------------------------------------------------------
    $stamped = 0; $skipped = 0; $outdated = 0; $failed = 0

    foreach ($file in $songFiles) {
        $songPath = "songs\$file"
        # token name = song name with .tsr instead of .txt
        $tokenName = [System.IO.Path]::GetFileNameWithoutExtension($file) + ".tsr"
        $tokenPath = "timestamps\$tokenName"

        if ($file -match " ") {
            # OpenSSL can't handle the space (see the note above
            # Push-Location). Hyphens work great instead.
            Write-Host "[RENAME]  '$file' has a space in its filename - rename it" -ForegroundColor Yellow
            Write-Host "          (e.g. use hyphens: my-song.txt) and update songs.js." -ForegroundColor Yellow
            $failed++
            continue
        }

        if (-not (Test-Path $songPath)) {
            Write-Host "[MISSING] $file is listed in songs.js but not in songs/" -ForegroundColor Red
            $failed++
            continue
        }

        if (Test-Path $tokenPath) {
            if (Test-TokenMatches $songPath $tokenPath) {
                Write-Host "[OK]      $file - already stamped, file unchanged" -ForegroundColor DarkGray
                $skipped++
                continue
            }

            # The song was edited after it was stamped.
            if (-not $Restamp) {
                Write-Host "[EDITED]  $file changed since its last stamp." -ForegroundColor Yellow
                Write-Host "          Run  .\timestamp-songs.ps1 -Restamp  to stamp the new version." -ForegroundColor Yellow
                $outdated++
                continue
            }

            # -Restamp: keep the old token (proof of the old version)
            # under a dated name, then stamp the current version.
            $archiveName = [System.IO.Path]::GetFileNameWithoutExtension($tokenName) +
                           ".superseded-" + (Get-Date -Format "yyyy-MM-dd") + ".tsr"
            Move-Item $tokenPath "timestamps\$archiveName"
            Write-Host "[ARCHIVE] kept old proof as timestamps/$archiveName" -ForegroundColor DarkGray
        }

        try {
            New-Timestamp $songPath $tokenPath
            Write-Host "[STAMPED] $file -> timestamps/$tokenName" -ForegroundColor Green
            $stamped++
        }
        catch {
            Write-Host "[FAILED]  $file - $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }

    # -------------------------------------------------------------
    # Summary + the reminder that matters most.
    # -------------------------------------------------------------
    Write-Host ""
    Write-Host "Done. $stamped stamped, $skipped already current, $outdated edited-but-kept, $failed failed."
    if ($stamped -gt 0) {
        Write-Host ""
        Write-Host "IMPORTANT: commit and push the new .tsr files with GitHub Desktop" -ForegroundColor Cyan
        Write-Host "so the proof is saved alongside the lyrics." -ForegroundColor Cyan
    }

    # Report success/failure to anything that ran this script
    # (otherwise PowerShell would reuse the last command's status).
    if ($failed -gt 0) { exit 1 } else { exit 0 }
}
finally {
    # Always return to whatever folder the user started in.
    Pop-Location
}
