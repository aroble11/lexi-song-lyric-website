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

## 2. Current status (as of 2026-07)

**Built, verified working, and published to GitHub.** The git repo is this folder,
pushed to `https://github.com/aroble11/lexi-song-lyric-website` (branch `main`).
Seven real songs are on the site, and every one has a FreeTSA timestamp token
(stamped 2026-06-20; all seven re-verified `Verification: OK` against the current
files on 2026-07-19).

- Hero name, page title, tagline, About bio, and footer are filled in (Lexi Robles).
- **Still placeholder:** the four social links in the About section
  (`COMING SOON` entries in `index.html`).
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
- **Fonts:** Google Fonts (Permanent Marker, Caveat, Courier Prime) loaded via
  `<link>`, plus two **local** families in `fonts/`: Lovers Quarrel (the artist
  name) and Mathilde (song titles, tagline, and the lyrics themselves).
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
│   ├── lovers-quarrel/      ← Lovers Quarrel .ttf + its OFL license text
│   └── mathilde/            ← Mathilde .otf (CC BY-SA 3.0; credited in the footer)
├── assets/
│   ├── background_inspiration.webp  ← THE page background (used by styles.css)
│   └── *.svg                ← ⚠ UNUSED leftovers (starfield, corner-roses,
│                              corner-cracks, heart-broken, splatter) — safe to delete
├── timestamps/              ← FreeTSA ownership proof
│   ├── README.txt           ← what the tokens are + how to verify
│   ├── cacert.pem           ← FreeTSA CA cert (downloaded; used to verify)
│   ├── tsa.crt              ← FreeTSA signing cert (downloaded; used to verify)
│   └── *.tsr                ← one proof token per song (all 7 stamped 2026-06-20)
├── timestamp-songs.ps1      ← PowerShell helper: stamps songs via OpenSSL + FreeTSA
├── .claude/launch.json      ← dev-only: preview server (python http.server, port 8742)
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
| **Expand-in-place cards** | `main.js` buildCard + `.lyrics-panel` CSS | Smooth height anim via `grid-template-rows: 0fr→1fr` trick. |
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

**Theme: edgy / punk / emo — "broken glass and roses."** A deep plum-black board
with a full-viewport photo background (`assets/background_inspiration.webp`: oxblood
roses, blood splatter, near-white glass cracks, a small hand-drawn broken heart)
behind dark "cracked-glass" song cards that glow crimson at the edges.

**Palette** (defined as CSS variables in `:root` at the top of `styles.css` — change
once, applies everywhere):
- `--bg #17131a` deep plum-black; `--bg-haze #2a2230` smoky center;
  `--bg-edge #0e0b11` near-black edges (also the body fallback color)
- `--text #ece8ea` cool bone on the board; `--muted #9a909a` ash grey
- **two pops of color:** `--crimson #b3202b` — THE accent (the name "Lexi", card
  borders/glows, hovers, open-card ×) — and `--oxblood #6e2433`, the deeper wine
  secondary; `--glass #dfe6ea` near-white for glass-crack hairlines
- inside cards: `--card-ink #f7a8b7` soft pink text on the dark card,
  `--card-ink-soft #a59db0` dimmed, `--card-accent` = crimson
- `--grain` an inline SVG-noise data-URI layered over board and cards

**Fonts:** Lovers Quarrel (the artist name, huge flowing script — title case, never
ALL CAPS), Mathilde (song titles, tagline, About heading, and the lyrics themselves —
reads as the owner's handwriting), Permanent Marker (marker accents like the "//"
slashes), Caveat (card teasers + story notes), Courier Prime (typed chips, labels,
buttons, footer).

**Background:** the photo lives on a fixed, full-viewport `.bg-photo` div (negative
z-index, `pointer-events: none`) with a dark scrim gradient over the image, anchored
`left center` at `cover` — wide screens see most of the image, phones crop into the
left third. The body keeps a near-black fallback color while the photo loads.

**Cards (the cracked-glass look):** dark slate (#1b1620) with a crimson border and
layered crimson glow (box-shadow), faint grain overlay, and a tiny per-card `--rot`
tilt (via `:nth-child(3n…)`) that **straightens flat when opened** for easy reading.
Lyrics render in Mathilde at 2.5rem with `line-height: 1.05` — tight handwritten
leading. **Do not go below ~1.05:** tighter values make wrapped lyric lines collide
vertically (this was a real bug, fixed 2026-07).

**Responsive:** mobile-first-friendly. `clamp()` type scale, fluid spacing,
`repeat(auto-fill, minmax(min(350px,100%), 1fr))` grid that flows desktop→tablet→phone.
Touch targets are large; hover effects mirrored by focus-within. Verified no
horizontal scroll at 375px.

**Motion:** every animation (ink flecks, easter egg, scroll hint, card
transitions) is disabled under `@media (prefers-reduced-motion: reduce)`.

---

## 8. Ownership / timestamping system (FreeTSA)

This is the "prove the lyrics are mine" half of the project. Two layers:

1. **GitHub commit history** — public, dated, but soft (commit dates come from the
   owner's own clock, can be altered).
2. **FreeTSA RFC 3161 trusted timestamps** — hard proof. `timestamp-songs.ps1` hashes
   each song (SHA-256) and gets an independently-signed `.tsr` token proving the file
   existed at that moment. **Only the hash is sent — lyrics never leave the machine.**
   Cannot be backdated. Anyone can verify with the certs in `timestamps/`.

**`timestamp-songs.ps1` behavior:**
- Auto-locates OpenSSL: PATH → Git-for-Windows install (derived from `git.exe`
  location, works on any drive) → common C: paths.
- Downloads FreeTSA `cacert.pem` + `tsa.crt` once into `timestamps/`.
- Reads the song list out of `songs.js` (regex for `"...txt"`).
- For each song: skips if already stamped & unchanged; flags edited songs;
  `-Restamp` archives the old token as `*.superseded-YYYY-MM-DD.tsr` and re-stamps.
- Verify command (also in `timestamps/README.txt`):
  `openssl ts -verify -data songs/<song>.txt -in timestamps/<song>.tsr -CAfile timestamps/cacert.pem -untrusted timestamps/tsa.crt` → `Verification: OK`.

**THE GOLDEN RULE:** a timestamp matches a file's *exact bytes*. Stamp songs when
finished. Editing a song invalidates its token — re-stamp with `-Restamp`; keep the
old token (it still proves the old version's date). A timestamp proves *existence by
a date*, not *authorship*.

**Hard-won gotchas baked into the script (don't reintroduce these bugs):**
- **OpenSSL 3 cannot handle file paths/filenames containing spaces** (it parses them
  as URIs). The script `Push-Location`s into the site folder and uses short relative
  paths; song **filenames must be space-free** (use hyphens). The script warns on a
  spaced filename.
- **`.ps1` must stay pure ASCII** for Windows PowerShell 5.1 — a stray em-dash/curly
  quote causes "string is missing the terminator" parser errors. Use plain ASCII
  punctuation in the script.
- **PowerShell's `Invoke-WebRequest` corrupts the binary timestamp upload/download.**
  Use `curl.exe` (ships with Win10/11) for the FreeTSA POST instead.
- OpenSSL prints harmless progress to stderr even on success → set
  `$ErrorActionPreference = "Continue"` around OpenSSL calls and judge by exit code.

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

Full step-by-step is in `README.md`. Key points:
- **Done:** the repo is initialized in this folder (never at its parent) and pushed
  to `https://github.com/aroble11/lexi-song-lyric-website`, branch `main`.
- The repo must stay **public** (public history is what makes the evidence visible).
- Settings → Pages → deploy from branch `main`, root folder. Expected URL:
  `https://aroble11.github.io/lexi-song-lyric-website/`.
- Publishing an update = commit in GitHub Desktop → **Push origin**; the live site
  refreshes within a couple of minutes.

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
- **Live search/filter box** (filter cards by title/lyrics as you type) — most useful
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
