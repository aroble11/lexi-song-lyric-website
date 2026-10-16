# PROJECT.md — Lyrics Showcase Site

> **Purpose of this file:** the single source of truth for *what this project is,
> why it's built the way it is, and how to continue it seamlessly*. `README.md` is
> the user-facing how-to (adding songs, deploying); this file is the developer/context
> brief. If you're picking this up cold, read this first.

---

## 1. What this is

A public, single-page website that showcases the owner's original song lyrics
(pop punk / rock genres). It serves two goals:

1. **Showcase** — a visually dynamic, modern page where each song is a clickable
   card that expands in place to reveal the full lyrics.
2. **Ownership evidence** — dated, verifiable proof the lyrics are the owner's,
   via GitHub commit history *and* FreeTSA trusted timestamps (the owner is not
   yet registering with the US Copyright Office).

**Owner / author:** Lexi Robles (artist/display name used in the hero + footer).
**Genres / vibe:** pop punk and rock; loves futuristic/space themes.
**Owner's skill level:** intermediate HTML/CSS, a little JavaScript, **beginner with
GitHub** (uses GitHub Desktop). → Keep all JS heavily commented in plain language;
explain git concepts simply.

---

## 2. Current status

**2026-10 notebook redesign: local review only, not published.** Approved reference: `design-mockups/01-personal-lyric-notebook-v2.png`. Monsters is featured; six other songs link from the sidebar; the entire collection below is searchable. Cards expand in place. Existing lyrics and timestamp files are unchanged.

### Earlier published baseline (2026-07)

**Built, verified working, and published to GitHub.** The git repo is this folder,
pushed to `https://github.com/aroble11/lexi-song-lyric-website` (branch `main`).
Seven real songs are on the site, and every one has a FreeTSA timestamp token
(stamped 2026-06-20; all seven re-verified `Verification: OK` against the current
files on 2026-07-19).

- Hero name, page title, tagline, About bio, and footer are filled in (Lexi Robles).
- **Contact links:** the empty About contact list stays hidden until real URLs
  are supplied. Search `EDIT ME: CONTACT LINKS` in `index.html` to add them.
- **To confirm on github.com:** GitHub Pages is enabled (Settings → Pages →
  deploy from `main`, root). If the live URL isn't serving, that's the switch.
- The two old demo songs (`songs/01-example-song-one.txt`, `-two.txt`) and the
  original `assets/background_inspiration.png` still exist on disk but are
  git-ignored — not part of the published site.

---

## 3. Tech stack & hard constraints

- **Plain static site:** HTML + CSS + vanilla JavaScript. **No build step, no
  frameworks, no dependencies, no bundler.** This is deliberate — the owner must be
  able to hand-edit everything forever. Do not introduce React/Vue/Tailwind/npm/etc.
- **Hosting target:** GitHub Pages (static file serving over HTTP).
- **Fonts:** Google Fonts (Caveat) loaded via
  `<link>`, plus local Lexi Notebook Regular/Bold for song titles. The artist name uses image
  artwork with screen blending and accessible heading text. Reading text uses Georgia. Older fonts are retained.
- **Browser support:** modern evergreen browsers. Uses `fetch`, CSS grid,
  `grid-template-rows: 0fr→1fr` animation, `clamp()`, CSS custom properties.
- **Keep JS commented** in plain English (owner reads it to learn).
- **Accessibility is a feature, not optional:** real `<button>` toggles,
  `aria-expanded`/`aria-controls`, `prefers-reduced-motion` honored everywhere.
- **Security detail that must be preserved:** lyrics are always injected with
  `.textContent`, **never** `.innerHTML`. This keeps `<`, `&`, `"` etc. in lyrics
  literal and unexploitable. Don't regress this.

---

## 4. File structure

```
lexi-song-lyric-website/      ← THIS folder is the git repo (not its parent!)
├── index.html               ← page shell: bg-photo div, hero, #lyrics-grid, About, footer
├── styles.css               ← ALL styling; re-theme via :root variables at top
├── main.js                  ← loads songs, builds cards, all interactivity (commented)
├── songs.js                 ← THE LIST: const SONGS = [...] filenames in display order
├── songs/                   ← THE LYRICS: one plain-text file per song
│   └── 01-monsters.txt … 07-where-are-you.txt   (7 real songs, all stamped;
│                              two git-ignored demo files also remain on disk)
├── fonts/
│   ├── lexi-notebook/       ← custom Regular/Bold TTF + WOFF2, source and specimen
│   ├── pinyonscript/        ← retained name font + OFL license
│   ├── thenautigal/         ← fallback title fonts + OFL license
│   └── lovers-quarrel/, mathilde/ ← retained legacy font files
├── assets/
│   ├── notebook-hero.webp / notebook-pressed-rose.webp ← transparent rose artwork
│   └── heart-broken.svg     ← featured paper doodle; other SVGs are legacy assets
├── timestamps/              ← FreeTSA ownership proof
│   ├── README.txt           ← what the tokens are + how to verify
│   ├── cacert.pem           ← FreeTSA CA cert (downloaded; used to verify)
│   ├── tsa.crt              ← FreeTSA signing cert (downloaded; used to verify)
│   └── *.tsr                ← one proof token per song (all 7 stamped 2026-06-20)
├── timestamp-songs.ps1      ← PowerShell helper: stamps songs via OpenSSL + FreeTSA
├── .claude/launch.json      ← dev-only: preview server (python http.server, port 8742)
├── EDITING.md               ← owner-facing "where do I edit X" directory; the code's
│                              ★ TWEAK / EDIT ME markers are indexed there — keep both
│                              in sync when adding features
├── README.md                ← user-facing how-to (add songs, deploy, prove ownership)
└── PROJECT.md               ← this file
```

---

## 5. How the site works (data flow)

1. `index.html` loads `songs.js` then `main.js`.
2. `songs.js` exposes `const SONGS = [...]` — an ordered array of `.txt` filenames.
3. On `DOMContentLoaded`, `main.js` runs four setup functions:
   `loadAllSongs()`, `setUpCursorGlow()`, `setUpSparkles()`, `setUpEasterEgg()`.
4. `loadAllSongs()` `fetch()`es every song file in parallel (`Promise.all`, which
   preserves order), parses each, and appends a card to `#lyrics-grid`.
5. `parseSong()` splits a file at the **first blank line**: everything above is the
   `Key: Value` header; everything below is lyrics (line breaks preserved).
6. `buildCard()` constructs the card DOM and wires up its behavior.

### Song file format (the contract — see §6 for fields)
```
Title: Neon Veins
Year: 2026
Status: finished
Story: Written after a long tour.   (optional, one line)

[Verse 1]
First line...
Second line...

[Chorus]
...
```
- First blank line ends the header. Lyrics shown exactly as typed.
- A whole line in `[Square Brackets]` is styled as a section label.
- **Filenames must use hyphens, not spaces** (OpenSSL timestamping can't handle
  spaces — see §8). The `NN-` number prefix is just for sorting; it's stripped from
  the share-link slug.

---

## 6. Features (all implemented)

| Feature | Where | Notes |
|---|---|---|
| **Expand-in-place cards** | `main.js` buildCard + `.lyrics-panel` CSS | Opened collection cards span both columns; the featured card stays in place; smooth opening, instant closing to prevent scrolling past the next song. |
| **Collapsed-panel access** | `setCardOpen` | Keeps `inert`, `aria-hidden`, `aria-expanded`, and visible state synchronized for clicks and incoming song links. |
| **One-open-at-a-time** | toggle click handler | Opening a card auto-collapses any other open card. |
| **Card chips** | buildCard | Shows `Year · Status`; hidden if neither present. |
| **Teaser preview** | buildCard | First 2 non-blank, non-`[section]` lyric lines on the closed card. |
| **Shareable song links** | buildCard + loadAllSongs | Each card `id` = slug. Opening updates URL hash (`replaceState`); visiting `...#slug` auto-opens + scrolls. |
| **Copy-link button** | buildCard | Inside open card; clipboard API w/ textarea fallback; flashes "✓ link copied!". |
| **Story behind the song** | buildCard | Optional `Story:` header line → "// THE STORY" block at bottom of open card. |
| **Site-wide cursor glow** | (removed) | The `.cursor-glow` div was taken out of `index.html`; `setUpCursorGlow()` stays as a harmless no-op (returns early when the div is absent). |
| **Click ink flecks** | `setUpSparkles` + `.sparkle` | 8 blood-spray specks (crimson/oxblood, occasional dark drop or pale glass fleck) burst on every `pointerdown` (mouse+touch); self-delete on `animationend`. Skipped under reduced-motion. |
| **Easter egg** | `setUpEasterEgg` + `.rockout` CSS | Click hero name 5× fast → ~1.6s title shake, the first name strobes colors, soft crimson/oxblood wash pulses. |
| **Error cards** | loadAllSongs | Missing/typo'd song → visible error card. Special note if opened via `file://`. |
| **`<noscript>` fallback** | index.html | Points JS-disabled visitors to the raw `songs/` folder. |

---

## 7. Design system

**Personal lyric notebook:** warm charcoal background, ivory torn paper, oxblood roses and broken glass. No white presentation strip. The margin note reads “trapped in my head.”

- Refinement: darker charcoal background, navigation ends before the roses, locally hosted Pinyon Script/The Nautigal fonts, worn paper texture and torn binding mask. Asset provenance: `design-mockups/notebook-refinement-assets.md`.
- Palette variables: `--bg`, `--text`, `--muted`, `--paper`, `--ink`, `--wine`.
- Wispy artist-name image artwork with screen blending; centered tagline tucked beneath the name; smoky charcoal background; stronger red collection numbers; thin date/status rules on collection cards; custom Lexi Notebook Regular collection titles and Bold featured title; small notebook-script note with a red broken-heart outline beside the rose; Georgia reading text. Font source, coverage, and rebuild notes: `fonts/lexi-notebook/README.md`.
- Lyrics/About navigation uses `aria-current` and a red underline, updated for clicks, browser history, and individual song links.
- `assets/notebook-hero.webp` and `assets/notebook-pressed-rose.webp` were generated from the approved mockup. Prompts/method: `design-mockups/notebook-asset-prompts.md`. All paper styling and visible wording remain live HTML/CSS.
- Desktop: featured paper plus six-song sidebar; full collection in two columns. Below 800px the sidebar moves below the feature; below 560px collection cards stack.
- `FEATURED_SONG` and `SIDEBAR_LIMIT` in main.js control the opening section. The feature retains its canonical share slug; its duplicate in the full collection uses an `archive-` ID. Both share buttons use the same canonical URL.
- Search covers titles, lyrics, years and stories. It never removes the feature/sidebar. Sidebar navigation clears search so linked songs remain visible.
- Name artwork and fixed-size torn binding holes: see `design-mockups/name-artwork-prompts.md`. The hole mask scales uniformly on phones to preserve round punches.
- One card opens at a time. Hidden panels use inert and aria-hidden. Opening animates; closing is immediate. Reduced-motion disables the animation and ink flecks.

---

## 8. Ownership evidence and timestamping

See [EVIDENCE.md](EVIDENCE.md) for the complete workflow. `scripts/lyric-evidence.ps1` provides shared PowerShell 5.1-compatible verification and packaging. `timestamp-songs.ps1` archives existing proofs or requests verified new stamps; intentional edits require `-Restamp` and a complete previous snapshot. Signature and certificate errors stop the process and are never treated as edits. Candidates are verified before atomic replacement; prior packages remain intact.

Every version under `timestamps/evidence/` contains exact lyric bytes, proof, certificates, and a manifest. `check-before-publish.ps1` is read-only/offline and fails on missing, edited, or invalid evidence. The prepared workflow gates its deployment on verification and explicit manual publishing. See PUBLISHING.md: branch-based Pages must be switched to GitHub Actions before a release push. The owner confirmed switching the Pages source to GitHub Actions during release preparation.

`.gitattributes` preserves exact stamped bytes. The publishing preparation stages the documented Git line-ending migration because historical Git blobs use LF while the existing stamps match local CRLF bytes; include it in the first release commit. Do not rewrite or normalize stamped files.

`backup-lyric-evidence.ps1` creates and reopens a versioned ZIP, verifies its entries, and writes a SHA-256 checksum. The user chose `evidence/` inside this repository; it is ignored by Git and requires `-AllowInsideRepository`. This is local recovery storage, not independent backup. Keep private drafts outside served folders. Tests use isolated copies and simulated transport; real signatures are checked with OpenSSL.

Timestamps establish existence of exact bytes by the signed date, not authorship or copyright registration. Keep these claims distinct in documentation and UI.

---

## 9. Local preview

The page uses `fetch()`, which browsers **block over `file://`** — double-clicking
`index.html` shows an error card by design. Preview with a local server:
- **Owner's way:** VS Code → Live Server extension → right-click `index.html` →
  "Open with Live Server" (auto-refreshes on save).
- **Dev/agent way:** the `lyrics-site` preview server in `.claude/launch.json`
  (python http.server, port 8742), or `py -m http.server` in the folder.

On live GitHub Pages this is a non-issue (served over HTTP).

**Preview tooling note:** during development the MCP `preview_screenshot` tool
intermittently times out even when the page is healthy — fall back to `preview_eval`
DOM/computed-style assertions to verify behavior when that happens.

---

## 10. Deployment (GitHub Pages)

Release instructions are in `PUBLISHING.md`. The repository is local to this
folder, with origin `https://github.com/aroble11/lexi-song-lyric-website` and branch
`main`. The prepared workflow validates evidence, packages only allowlisted public
files, and deploys only on an explicit manual run after verification succeeds.
Before a release push, change Pages' source to **GitHub Actions**; the old
branch-based source operates independently. The owner confirmed this Pages source change during release preparation.
Expected site URL: `https://aroble11.github.io/lexi-song-lyric-website/`.

---

## 11. Environment notes (the owner's machine)

- Windows 11. The repo lives at
  `C:\Users\sapph\Documents\GitHub\WEBSITE\lexi-song-lyric-website`.
- **Git is installed on the D: drive** (`D:\Program Files\Git`), not C: — relevant
  for any tool that hunts for OpenSSL/git. The timestamp script derives the path from
  `git.exe` so it already handles this (verified 2026-07: it finds
  `D:\Program Files\Git\usr\bin\openssl.exe`).
- Shell: PowerShell primary (5.1 syntax constraints apply); Bash tool also available.
- Python: invoking `python`/`py` may hit the Windows Store alias depending on context;
  the launch.json server worked via the preview tool. `curl.exe` is available.

---

## 12. This project is independent

Built entirely from scratch. It deliberately does **not** reference, reuse, or borrow
from the owner's unrelated `raptor-gallery` project (the owner explicitly required
this). Keep it self-contained.

---

## 13. Ideas considered but NOT yet built (backlog)

From an earlier brainstorm; the owner picked shareable links, story notes, cursor
glow, About section, and the easter egg (all done). Still on the table if asked:
- **Search is implemented** (title/lyrics/year/story); future refinements may be useful
  once the catalog grows past ~15 songs.
- **"Favorite line" pull-quote** — optional `Favorite:` header line shown glowing on
  the closed card face instead of / alongside the teaser.
- **Audio demos** — `<audio>` player inside the open card if the owner records demos.
  Biggest possible upgrade; no framework needed.
- **Sort/filter chips** (Newest · A–Z · Finished-only) using existing Year/Status data.
- Explicitly **declined:** comments section / visitor counter (need 3rd-party
  services, add clutter + moderation, age badly).

---

## 14. How to continue in a new conversation

1. Read this file, then `README.md` (user-facing) and skim `main.js` (all behavior
   lives there, well-commented).
2. To add a feature: it's vanilla JS in `main.js` + styles in `styles.css`. Follow the
   existing commented-block style. Keep `.textContent` for any lyric/user text.
   Honor reduced-motion. Verify with the `lyrics-site` preview server.
3. To touch timestamping: re-read §8 gotchas before editing `timestamp-songs.ps1`.
4. Don't add a build step or dependencies. Don't init git at the parent folder.
5. Verify changes in-browser (preview server on :8742) before declaring done.
