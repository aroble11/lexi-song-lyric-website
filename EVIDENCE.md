# Lyric evidence and recovery

This system records when exact lyric-file bytes existed. It does not independently certify authorship or register copyright. Keep original drafts, notebook scans, recordings, and writing correspondence as separate supporting evidence.

## What is saved

Each version in `timestamps/evidence/<song>/<signed-date>-<fingerprints>/` contains:

- `lyrics.txt`: the exact bytes that were stamped, including headers and line endings.
- `proof.tsr`: the original signed FreeTSA response.
- `cacert.pem` and `tsa.crt`: the public certificates used to verify it.
- `manifest.json`: the filename, title, signed UTC timestamp, SHA-256 fingerprints of all four files, and the separate package-creation time.

The signed timestamp comes from the verified token, not the computer clock. Manifest labels and the package-creation date are supporting metadata, not independently signed authorship claims. Existing packages are validated and never overwritten by the tools. They are not filesystem-immutable: retain Git history and separate backups to protect against manual deletion.

The seven initial packages retain their original June 20, 2026 timestamps. Packaging them now did not request new dates or alter the original lyric files, tokens, or certificates.

## Normal workflow

For a new song, add its text file and list it in `songs.js`, then run:

```powershell
.\timestamp-songs.ps1
```

For an intentional edit to an already-stamped song:

```powershell
.\timestamp-songs.ps1 -Restamp
```

The old version must already have a complete verified package. If it does not, the tool stops and asks you to recover the original bytes. It never pretends that the edited text is the old snapshot. Missing certificates or signature failures also stop the process; they are not treated as edits.

New stamps use a captured copy of the lyrics. Only its SHA-256 timestamp query goes to FreeTSA. A response is checked against the original query (including its nonce), its signed fingerprint, and the certificates. A complete package is saved before the current `.tsr` is atomically replaced. Changed source files during the request cause the operation to stop. Failed requests retain the old proof and clean up their own temporary files. Concurrent stamp writers are blocked by a file lock.

To package existing valid proofs without sending any requests:

```powershell
.\timestamp-songs.ps1 -ArchiveOnly
```

## Before publishing

```powershell
.\check-before-publish.ps1
```

This is read-only and offline. It checks current songs, the corresponding complete packages, and all other archived version folders. Missing, edited, corrupt, incomplete, or unverifiable evidence exits **1**. Success exits **0**. It does not automatically fix, re-stamp, upload, or deploy anything.

The prepared **Validate and publish site** workflow verifies and packages the site before its dependent deployment job can run. Deployment requires a manual run from `main` with **Publish: true**; normal checks do not deploy. This workflow is local and has not run on GitHub yet. Existing branch-based Pages publishing remains independent until the repository's publishing source is switched to GitHub Actions. See [PUBLISHING.md](PUBLISHING.md) before pushing a release.

### One-time Git line-ending migration

The old Git blobs contain LF line endings while the original proofs match your local CRLF files. `.gitattributes` now disables text normalization for stamped files and version packages. No lyric wording or local file bytes were changed.

The local publishing preparation stages the attributes and re-adds the existing song entries under the new rules using:

```powershell
git add .gitattributes
git add --renormalize songs/
```

Include the new scripts, workflow, packages, and documentation in that same commit. This is an intentional Git storage change to preserve the already-stamped bytes. Only the attributes and tracked song bytes are staged by that migration; nothing is committed, pushed, or published. Future checkouts will match only after the exact-byte migration is committed; the CI check will reject mismatches rather than silently accept normalized versions.

## Backups

The user-selected local recovery destination is `evidence/` inside this repository. It is excluded from Git. Create another versioned ZIP there with:

```powershell
.\backup-lyric-evidence.ps1 -Destination "$PWD\evidence" -AllowInsideRepository
```

The ZIP includes the listed current songs, current and archived proofs, certificates, song list, verifier, and byte-preservation rules. Every entry is hashed after reopening the ZIP, and a `.zip.sha256` checksum is saved. Existing ZIPs are never overwritten. The backup tool refuses an in-repository destination unless explicitly allowed.

**This folder is a local recovery copy, not an independent backup.** Deleting or losing the whole website directory can lose both. For independent protection, give the tool a folder on an external drive or private backed-up storage. Gitignore prevents ordinary Git additions; it is not access control, and a local static server can serve files in `evidence/`. Do not put confidential drafts in it.

To recover a package, keep `lyrics.txt`, `proof.tsr`, and the certificates together. From that package folder:

```powershell
openssl ts -verify -data lyrics.txt -in proof.tsr -CAfile cacert.pem -untrusted tsa.crt
openssl ts -reply -in proof.tsr -text
```

The included PowerShell checker can verify an extracted backup as a whole. Verification uses certificate checks; a future certificate expiry or trust change must be reviewed rather than bypassed or mistaken for altered lyrics. See [OpenSSL's timestamp documentation](https://docs.openssl.org/3.0/man1/openssl-ts/).

## Private writing history

Keep a separate private folder **outside the repository and outside any served website folder**. Save dated drafts as new versions, retain original scans/voice memos, and optionally maintain a short writing log (song, date, draft filename, and what changed). Do not rewrite old drafts to make them look earlier. Nothing in this upgrade searches, uploads, or relocates your private material. Existing documents remain where you put them.

Copyright registration is separate and has not been performed. Its requirements and benefits depend on the work and timing; see the [U.S. Copyright Office registration overview](https://www.copyright.gov/engage/docs/registration.pdf).

## Validation

`tests/lyric-evidence.tests.ps1` tests migration, exact-byte preservation, read-only checks, edited/missing/corrupt evidence, invalid certificates, failed transport, wrong-file replies, successful replacement with preserved history, and backup ZIP verification. Tests use isolated copies and real existing signatures; network transport is replaced with local fixtures, so they do not contact FreeTSA or change real songs.
