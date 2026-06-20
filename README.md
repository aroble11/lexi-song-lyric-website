# My Lyrics Site

A single-page showcase for original song lyrics. Plain HTML/CSS with a small amount of
commented JavaScript — no build tools, no frameworks. Songs live as plain text files;
the page turns them into clickable cards that expand in place.

```
lyrics-site/
├── index.html          ← the page (hero, grid, footer)
├── styles.css          ← all styling; re-theme via the variables at the top
├── main.js             ← loads the songs and builds the cards (commented)
├── songs.js            ← ★ THE LIST: which songs appear, in what order
├── songs/              ← ★ THE LYRICS: one plain-text file per song
├── assets/starfield.svg← the tiled star background
├── timestamps/         ← proof-of-date tokens (see "Proving ownership")
├── timestamp-songs.ps1 ← script that creates those tokens
└── README.md           ← this file
```

★ = the only two places you touch when adding songs.

---

## Before you publish: fill in the placeholders

Open `index.html` and search for **`EDIT ME`** — the spots are:

1. The page `<title>` and description (helps search engines)
2. Your artist/display name in the hero
3. The tagline under your name
4. Your bio in the About section
5. Your social/contact links in the About section (replace the `#` placeholders,
   delete any you don't use)
6. Your name in the footer copyright line

Then replace the two example songs (below) with real ones.

## Neat tricks built into the page

- **Share one song:** open a card and the address bar updates to a direct link
  (like `...#neon-veins`) — or use the "copy link" button inside the open card.
  Anyone visiting that link lands with that song already open.
- **The story behind a song:** add a `Story:` line to a song file's header and
  it shows up inside the opened card.
- **Ink flecks:** clicking (or tapping) anywhere flicks a little spatter of ink across the page.
- **Easter egg:** click the big name in the hero five times, fast. 🤘

---

## Adding a song (2 steps)

**Step 1.** Create a new text file in `songs/`, e.g. `songs/03-neon-veins.txt`.
Copy-paste this template:

```
Title: Neon Veins
Year: 2026
Status: finished

[Verse 1]
First line of the song
Second line of the song

[Chorus]
And so on...
```

Rules of the format (all of them):
- The top lines are `Key: Value` info. `Title` is used as the card heading;
  `Year` and `Status` show in the small chip (leave them out to hide the chip).
- Optional: a `Story:` line — one sentence about how the song came to be. If
  present, it appears as "// THE STORY" at the bottom of the opened card.
  (It has to stay on one line in the file.)
- **The first blank line ends the info section** — everything after it is lyrics,
  shown exactly as typed, line breaks included.
- A line in `[Square Brackets]` is treated as a section name and styled differently.
- Use hyphens instead of spaces in the **filename** (`neon-veins.txt`, not
  `neon veins.txt`) — the timestamping tool can't handle spaces in filenames.

**Step 2.** Open `songs.js` and add the filename to the list:

```js
const SONGS = [
  "01-example-song-one.txt",
  "02-example-song-two.txt",
  "03-neon-veins.txt",        // ← new line
];
```

Songs appear on the page in this list's order. To remove or reorder songs, edit the list.

---

## Previewing locally

Because the page loads song files with `fetch()`, browsers won't run it from a
double-clicked file (`file://` pages can't fetch). Preview with a tiny local server —
either option takes seconds:

- **VS Code:** install the *Live Server* extension once, then right-click
  `index.html` → **Open with Live Server**.
- **PowerShell (if Python is installed):** run `py -m http.server` in this folder,
  then open <http://localhost:8000> in your browser.

On the live GitHub Pages site this is a non-issue — it just works.

---

## Putting it on GitHub (and getting the free website)

> **Important:** the repository is **this folder only** (`lyrics-site/`), not the
> parent folder it sits in.

1. **GitHub Desktop** → *File → New repository…* → set **Local path** to the folder
   that *contains* `lyrics-site` and **Name** to `lyrics-site` (Desktop joins them),
   or use *File → Add local repository* and pick this folder, letting it create the repo here.
2. Commit everything, then click **Publish repository**. **Untick "Keep this code
   private"** — a public repo is what makes your dated history visible to others.
3. On github.com, open the repo → **Settings → Pages** → under *Build and deployment*
   choose **Deploy from a branch**, branch `main`, folder `/ (root)` → **Save**.
4. After a minute or two your site is live at
   `https://YOURUSERNAME.github.io/lyrics-site/`.

From then on, publishing an update = commit in GitHub Desktop → **Push origin**.
The site refreshes itself within a couple of minutes.

---

## Proving ownership

Three layers, weakest to strongest:

1. **The public site + git history.** Every commit is dated and public. Good
   supporting evidence, but commit dates come from your own computer's clock.
2. **Trusted timestamps (this repo includes the tooling).** Run:

   ```powershell
   .\timestamp-songs.ps1
   ```

   For each song it asks **FreeTSA.org** (a free, independent timestamping authority)
   to sign a statement that your exact file existed at that moment. The signed proof
   is saved as `timestamps/<song>.tsr`. **Your lyrics never leave your computer** —
   only a SHA-256 fingerprint is sent. Commit and push the `.tsr` files afterward.

   - **The golden rule:** a timestamp matches the file's *exact bytes*. Stamp songs
     when they're finished. If you edit one later, run
     `.\timestamp-songs.ps1 -Restamp` — it keeps the old token (still valid proof of
     the old version) and stamps the new one.
   - Anyone can verify a token — see `timestamps/README.txt` for the one-line command.
   - Honest caveat: a timestamp proves the file *existed by a date*, not who wrote it.
3. **US Copyright Office registration** (later, for songs you really care about).
   Registration is what unlocks the ability to sue and statutory damages in the US.

### Copyright notice

All lyrics in this repository are original works. **All rights reserved.** No license
is granted for reproduction, distribution, or derivative use. (This repo deliberately
contains no LICENSE file — under GitHub's terms, that means default copyright applies.)
