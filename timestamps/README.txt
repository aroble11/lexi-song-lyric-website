LYRIC EVIDENCE
==============

Current *.tsr files are FreeTSA RFC 3161 timestamp responses for the
corresponding songs/*.txt files. They certify existence of exact file
bytes by the signed UTC date, not the identity of the writer.

Complete version packages are in evidence/<song>/<version>/:
  lyrics.txt    Exact stamped lyric bytes, including line endings
  proof.tsr     Original signed timestamp response
  cacert.pem    Public trust certificate
  tsa.crt       Public signer certificate
  manifest.json Title, filename, signed UTC date, and SHA-256 hashes

Old packages are retained when new versions are stamped. Do not edit
these files. Package labels are metadata; the signed proof is the
independent date evidence. Retain separate backups and writing history.

FROM THE REPOSITORY ROOT
  .\check-before-publish.ps1
      Offline and read-only. Missing/changed/invalid evidence exits 1.
  .\timestamp-songs.ps1
      Archive valid current proofs and stamp new songs.
  .\timestamp-songs.ps1 -ArchiveOnly
      Package existing valid proofs without network requests.
  .\timestamp-songs.ps1 -Restamp
      Stamp intentional edits after verifying the old version package.

FROM AN INDIVIDUAL PACKAGE FOLDER
  openssl ts -verify -data lyrics.txt -in proof.tsr -CAfile cacert.pem -untrusted tsa.crt
  openssl ts -reply -in proof.tsr -text

A certificate/trust verification failure is not proof of edited lyrics.
Do not disable verification to make an error disappear. Review the cause.

See ../EVIDENCE.md for backups, exact-byte Git migration, the prepublish
workflow, private writing history, and the limits of this evidence.
