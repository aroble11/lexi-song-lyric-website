WHAT IS IN THIS FOLDER
======================

This folder holds cryptographic proof that the song files in ../songs/
existed on specific dates. The proof comes from FreeTSA.org, a free,
independent "trusted timestamping authority."

  *.tsr        One timestamp token per song. Each token is a signed
               statement from FreeTSA: "a file with this exact
               fingerprint existed at this exact date and time."
               Tokens named *.superseded-YYYY-MM-DD.tsr are older
               proofs kept after a song was edited and re-stamped —
               they still prove the earlier version's date.

  cacert.pem   FreeTSA's public certificates. These are the same for
  tsa.crt      everyone and are only used to VERIFY tokens. Keeping
               copies here means the proof in this repo can be
               checked forever, even offline.

HOW TO VERIFY A TOKEN
=====================

Anyone with OpenSSL (included with Git for Windows) can check a
token. From the folder above this one, run:

  openssl ts -verify -data songs/SONGNAME.txt -in timestamps/SONGNAME.tsr -CAfile timestamps/cacert.pem -untrusted timestamps/tsa.crt

If the song file is byte-for-byte identical to what was stamped, it
prints:  Verification: OK

To see the date and time inside a token:

  openssl ts -reply -in timestamps/SONGNAME.tsr -text

WHAT THIS PROVES (AND WHAT IT DOESN'T)
======================================

A token proves the file EXISTED no later than the stamped moment.
It cannot be backdated or forged without breaking FreeTSA's
cryptographic signature. It does not, by itself, prove who WROTE
the file — authorship is supported by the public site, the git
history, and (eventually) formal copyright registration.

HOW TOKENS ARE CREATED
======================

Run ..\timestamp-songs.ps1 — see the comments at the top of that
script for full instructions.
