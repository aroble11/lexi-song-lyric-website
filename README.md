# My Lyrics Site

A single-page showcase for original song lyrics. Plain HTML/CSS with a small amount of
commented JavaScript — no build tools, no frameworks. Songs live as plain text files;
the page turns them into clickable cards that expand in place.

> **Want to change something?** See **[EDITING.md](EDITING.md)** — it maps every
> kind of change (card size, colors, links, songs…) to the exact file and the
> exact search term that jumps you to the right spot.

```
lexi-song-lyric-website/
├── index.html          ← the page (hero, grid, About, footer)
├── styles.css          ← all styling; re-theme via the variables at the top
├── main.js             ← loads the songs and builds the cards (commented)
├── songs.js            ← ★ THE LIST: which songs appear, in what order
├── songs/              ← ★ THE LYRICS: one plain-text file per song
├── assets/             ← background photo, share-preview card, favicon
├── fonts/              ← local calligraphy fonts and licenses
├── timestamps/         ← proof-of-date tokens (see "Proving ownership")
├── timestamp-songs.ps1 ← script that creates those tokens
├── EDITING.md          ← where-to-edit guide for every part of the site
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
5. Your social/contact links in the About section (add real links under
   `EDIT ME: CONTACT LINKS`, then remove `hidden` from that list)
6. Your name in the footer copyright line

Then replace the two example songs (below) with real ones.

## Neat tricks built into the page

- **Notebook layout:** Monsters is featured, with six other songs in the sidebar.
  **View all lyrics (N)** leads to the complete collection, searchable by title, lyrics, year, or story.
- **Comfortable reading:** paper cards expand in place; opened collection cards span the grid.
  Lyrics and story notes use the notebook's serif reading font.
- **Keyboard access:** closed panels keep their lyrics and copy buttons out
  of keyboard navigation and the accessibility tree until opened.
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

## Publishing the website

See [PUBLISHING.md](PUBLISHING.md). The prepared workflow verifies the lyric evidence and builds an explicit public-file package before a dependent deployment job can run. Publishing is a separate manual action. Before the release is pushed, GitHub Pages must be switched to **GitHub Actions**; branch-based publishing bypasses the prepared gate.

Local preparation does not publish. Run `./prepare-site.ps1` to create a fresh `_site/` folder containing only the website files.

---

## Proving ownership

The site and Git history support your authorship record. FreeTSA timestamps independently certify when exact lyric-file bytes existed; they do not independently prove authorship or register copyright.

Every stamped version now has its own exact lyrics, signed proof, certificates, and manifest under `timestamps/evidence/`. Run `timestamp-songs.ps1` for new songs, or add `-Restamp` for intentional changes. Prior packages are retained, and failed requests do not replace valid proofs.

Before publishing, run `check-before-publish.ps1`. It is offline/read-only and exits with failure for edited, missing, or invalid evidence. The prepared publishing workflow requires verification before deployment; see PUBLISHING.md for the separate activation step.

See [EVIDENCE.md](EVIDENCE.md) for the one-time Git byte-preservation migration, backup commands, private draft guidance, and verification details. The user-selected `evidence/` folder contains ignored local recovery ZIPs; it is not an independent backup or a private web-server boundary.

### Copyright notice

All lyrics in this repository are original works. **All rights reserved.** No license
is granted for reproduction, distribution, or derivative use. (This repo deliberately
contains no LICENSE file — under GitHub's terms, that means default copyright applies.)
