# EDITING.md — where to change anything on this site

This is the "directory" for the whole project: find the thing you want to
change in here, and it tells you **which file to open and what to search for**.

## How to find the right spot (the one trick)

Every common editing spot in the code is marked with a searchable comment:

- **`EDIT ME`** — in `index.html`, marks *content* spots (your name, bio,
  links, tagline).
- **`★ TWEAK`** — in `styles.css`, `main.js`, and `songs.js`, marks *looks and
  behavior* spots (sizes, colors, animations).

Open the file in VS Code, press **Ctrl+F**, and type the marker name from the
recipes below (e.g. `★ TWEAK: CARD SIZE`). You'll land exactly where you need
to be, with a comment explaining what to change.

## The workflow, every time

1. **Edit** the file (recipes below).
2. **Preview**: right-click `index.html` → *Open with Live Server* (the page
   auto-refreshes as you save). Don't just double-click the file — the songs
   won't load that way (browsers block it; you'll see a note explaining).
3. **Publish**: in GitHub Desktop, write a short summary, **Commit to main**,
   then **Push origin**. The live site updates itself in a minute or two.

## What every file is

| File / folder | What it is |
|---|---|
| `index.html` | The page's skeleton: hero, About section, footer, links. **All content edits happen here.** |
| `styles.css` | Every visual style: colors, fonts, sizes, spacing, animations. |
| `main.js` | The behavior: loads songs, builds cards, click handling, effects. |
| `songs.js` | **The song list** — which songs show, in what order. |
| `songs/` | One plain-text file per song (the actual lyrics). |
| `EDITING.md` | This guide. |
| `README.md` | The original how-to (adding songs, deploying, proving ownership). |
| `PROJECT.md` | The deep technical brief (for future development work). |
| `assets/` | Images: background photo, share-preview card, favicon, spare art. |
| `fonts/` | The two local fonts (Lovers Quarrel = your name, Mathilde = titles + lyrics). |
| `timestamps/` | Proof-of-date tokens for your songs. **Never edit these.** |
| `timestamp-songs.ps1` | The script that creates those tokens. |

---

## Recipes — content

### Add a new song
1. Create a text file in `songs/`, e.g. `songs/08-new-song.txt`. **Use hyphens,
   never spaces, in the filename.** Format (first blank line ends the info block):
   ```
   Title: New Song
   Year: 2026
   Status: finished
   Story: One line about how it came to be.   (optional)

   [Verse 1]
   The lyrics, exactly as you want them shown...
   ```
2. Open `songs.js` → search **`★ TWEAK: SONG LIST`** → add `"08-new-song.txt",`
   to the list. (List order = page order.)
3. Preview, then timestamp it: open PowerShell in this folder and run
   `.\timestamp-songs.ps1` (see the timestamping recipes below).
4. Commit and push **both** the song and its new `timestamps/*.tsr` file.

### Remove or reorder songs
`songs.js` → **`★ TWEAK: SONG LIST`** → delete or move lines. The `.txt` file
can stay in `songs/`; only the list controls the page.

### Add your social media links
`index.html` → search **`EDIT ME`** → the block with `social-links`. Swap each
`#` for your real URL, e.g.
`<li><a href="https://instagram.com/yourhandle">Instagram</a></li>`.
Delete any `<li>` you don't use. For email use `href="mailto:you@example.com"`.

### Change your bio, tagline, or name
All in `index.html` — search **`EDIT ME`**; there's a marked block for each
(hero name, tagline, About bio, footer name).

### Change the browser-tab title or search-engine description
`index.html` → the `<title>` and `<meta name="description">` lines at the top
(first `EDIT ME` block).

---

## Recipes — look & layout

All in `styles.css`. Search the marker, change the number/color, save, look at
the preview. Every color used anywhere is defined once at the top.

| I want to change… | Search for | What you'll adjust |
|---|---|---|
| Card size / how many columns | `★ TWEAK: CARD SIZE` | The `350px` minimum width; the `gap` between cards |
| Any color on the site | `★ TWEAK: COLORS` | The variable block — one change applies everywhere |
| Card text colors, border, glow | `★ TWEAK: CARD LOOK` | `--card-ink` (lyrics/title color on cards), border, shadows |
| Which fonts are used where | `★ TWEAK: FONTS` | The `--font-*` variables |
| Size of your name in the hero | `★ TWEAK: NAME SIZE` | The `clamp(smallest, fluid, biggest)` values |
| Song title size on cards | `★ TWEAK: TITLE SIZE` | `font-size` |
| Lyrics handwriting size/spacing | `★ TWEAK: LYRICS SIZE` | `font-size`, `line-height` — **keep line-height ≥ 1.05** or wrapped lines collide |
| The background photo / darkness | `★ TWEAK: BACKGROUND PHOTO` | The image `url(...)`; the scrim `0.32` numbers (higher = darker) |
| Card tilt (or make them straight) | `★ TWEAK: CARD TILT` | The three `--rot` angles |
| Overall page width | `★ TWEAK: PAGE WIDTH` | `max-width` |

To swap the background photo: drop the new image into `assets/`, then point the
`url(...)` at it. Prefer `.webp` or a compressed `.jpg` (a huge file makes the
site slow to load).

---

## Recipes — behavior

All in `main.js`. It's more code-like in there, but each marked spot has a
comment telling you exactly which number or line to touch.

| I want to change… | Search for | Notes |
|---|---|---|
| How many preview lines on closed cards | `★ TWEAK: TEASER` | Change the `2` in `slice(0, 2)` |
| How fast cards open/close | `★ TWEAK: OPEN/CLOSE SPEED` | (this one's in **styles.css**) — the `0.35s` |
| Ink flecks: how many, what colors, off | `★ TWEAK: INK FLECKS` | Count + color list; delete the `setUpSparkles()` call at the bottom of the file to disable |
| The easter egg timing, or remove it | `★ TWEAK: EASTER EGG` | 5 clicks / 1.5s window / 1.6s glitch |
| Let multiple cards stay open at once | `★ TWEAK: ONE-AT-A-TIME` | Delete the marked `forEach` block |
| The copy-link button's label | `★ TWEAK: BUTTON TEXT` | Just the string |

---

## Recipes — timestamping (proof your songs existed)

Full background is in `README.md` ("Proving ownership") and
`timestamps/README.txt`. Day to day, it's just this:

- **After adding a new song:** open PowerShell in this folder and run
  `.\timestamp-songs.ps1` — it stamps anything unstamped and skips the rest.
  Commit + push the new `.tsr` file it creates.
- **After editing an existing song:** run `.\timestamp-songs.ps1 -Restamp` —
  it keeps the old proof (renamed with a date, still valid for the old
  version) and stamps the new version. Commit + push.
- **The golden rule:** a timestamp matches a file's *exact bytes*. Editing a
  stamped song is fine — just re-stamp it afterward.
- If Windows refuses to run the script:
  `powershell -ExecutionPolicy Bypass -File .\timestamp-songs.ps1`

---

## Everything else (quick lookup)

| Thing | File | Find it by searching |
|---|---|---|
| Footer copyright line | `index.html` | `EDIT ME` (footer block) |
| Font credits in the footer | `index.html` | `footer-small` |
| Browser-tab icon (favicon) | `assets/favicon.svg` + `.png` | — (ask a developer/Claude to regenerate) |
| Link-preview image for chats/socials | `assets/share-card.jpg` | — (regenerate rather than hand-edit) |
| Link-preview text (title/description) | `index.html` | `og:` |
| "Couldn't load…" error card wording | `main.js` | `error-card` |
| No-JavaScript fallback note | `index.html` | `noscript` |
| The bouncing scroll-down arrow | `styles.css` | `scroll-hint` |
| "YEAR · STATUS" chip styling | `styles.css` | `card-chips` |
| "// THE STORY" block styling | `styles.css` | `song-story` |
| The dashed badge above your name | `index.html` / `styles.css` | `hero-eyebrow` |
| Keyboard focus ring color | `styles.css` | `focus-visible` |
| Reduced-motion behavior | `styles.css` | `prefers-reduced-motion` |

---

## Rules that keep the site safe (please don't break these)

1. **Song filenames: hyphens, never spaces** (`my-song.txt`). The timestamp
   tool can't handle spaces.
2. **Never edit anything in `timestamps/`** — those files are cryptographic
   proof; changing a byte destroys it.
3. **Don't rename song files casually after sharing links** — the share link
   (`...#my-song`) comes from the filename, so a rename breaks old links.
4. If you ever edit `main.js` beyond the marked spots: lyrics must always be
   inserted with `.textContent`, never `.innerHTML` (this is what makes it
   impossible for a `<` or `&` in your lyrics to break the page).
5. `timestamp-songs.ps1` must stay plain ASCII — fancy quotes or long dashes
   in that one file break PowerShell.
6. If the site ever moves off
   `https://aroble11.github.io/lexi-song-lyric-website/`, update the `og:url`
   and `og:image` lines in `index.html` (they must be full absolute URLs).
