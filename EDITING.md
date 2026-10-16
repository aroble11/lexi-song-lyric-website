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
recipes below (e.g. `★ TWEAK: COLORS`). You'll land exactly where you need
to be, with a comment explaining what to change.

## The workflow, every time

1. **Edit** the file (recipes below).
2. **Preview**: right-click `index.html` → *Open with Live Server* (the page
   auto-refreshes as you save). Don't just double-click the file — the songs
   won't load that way (browsers block it; you'll see a note explaining).
3. **Prepare**: run `prepare-site.ps1` to verify evidence and create a public-only
   package. Follow [PUBLISHING.md](PUBLISHING.md) for activation and manual release.
   Do not push the release while Pages still uses the old branch-based source.

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
| `fonts/` | Lexi Notebook Regular/Bold = song titles; older font families are retained. The artist name is image artwork blended onto the page. |
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
`index.html` → search **`EDIT ME: CONTACT LINKS`** → add a real link inside
the `social-links` list, e.g.
`<li><a href="https://instagram.com/yourhandle">Instagram</a></li>`.
Remove `hidden` from the `<ul>` when a real link is ready. For email use
`href="mailto:you@example.com"`. The empty list stays hidden until then.

### Change your bio, tagline, or name
All in `index.html` — search **`EDIT ME`**; there's a marked block for each
(hero name, tagline, About bio, footer name).

### Change the browser-tab title or search-engine description
`index.html` → the `<title>` and `<meta name="description">` lines at the top
(first `EDIT ME` block).

---

## Recipes — look & layout

The main colors and fonts are under `★ TWEAK: COLORS` and `★ TWEAK: FONTS` in `styles.css`. Layout rules also have phone/tablet overrides at the bottom.

| I want to change… | Search for in styles.css | What to adjust |
|---|---|---|
| Overall width | `.site-shell` | `max-width` and padding |
| Smoky background | `--bg` and `.bg-photo` | Dark charcoal base; `assets/notebook-smoke.webp` supplies the wisps. Adjust opacity to change their strength. |
| Artist name | `.hero h1` and `.name-artwork` | Image width and spacing; artwork is `assets/lexi-robles-wispy.webp` |
| Tagline | `.tagline` and the tagline in index.html | Centered to the name artwork at each screen width |
| Active navigation underline | `.section-link[aria-current="location"]::after` | Red line follows Lyrics/About links and browser history |
| Note and heart beside the rose | `.margin-note`, `.paper-heart` | Notebook lettering and red outline in `assets/heart-broken.svg` |
| Rose cluster | `.hero-roses` | Size and position; source is in index.html |
| Paper color and edges | `.song-card::before` | Paper background and edge shape |
| Featured paper | `.featured-card` | Cover padding, title size, notebook ruling |
| Song titles | `.card-title` | Lexi Notebook Regular, weight 400; `.featured-card .card-title` uses Bold, weight 700 |
| Reading text | `.lyrics-text` | Font size and line height |
| Collection columns | `.lyrics-grid` | Grid columns and gap |
| Sidebar | `.collection-links` | Row spacing and type size |
| Date/status divider | `.card-meta-rule` | Thin centered rule between the year and status on collection cards |

In `main.js`, search `★ TWEAK: FEATURED SONG` to choose the featured file, `SIDEBAR_LIMIT` to change the six-song limit, and `★ TWEAK: MARGIN NOTE` for “trapped in my head.” The count and full searchable collection update automatically when you add songs to `songs.js`. Future titles automatically use Lexi Notebook; no title images are needed. Installable TTFs, an interactive specimen, and editable font source are in `fonts/lexi-notebook/`.

Artwork lives in `assets/notebook-hero.webp` and `assets/notebook-pressed-rose.webp`. Keep replacement images transparent. The worn paper texture is `assets/notebook-paper-worn.webp`; binding tears are `assets/notebook-torn-edge.svg`. CSS adds ruling and paper edges. Song wording stays editable; the decorative artist name is `assets/lexi-robles-wispy.webp`, with accessible heading text in index.html.

---

## Recipes — behavior

All in `main.js`. It's more code-like in there, but each marked spot has a
comment telling you exactly which number or line to touch.

| I want to change… | Search for | Notes |
|---|---|---|
| How many preview lines on closed cards | `★ TWEAK: TEASER` | Change the `2` in `slice(0, 2)` |
| How fast cards open | `★ TWEAK: OPEN/CLOSE SPEED` | (this one's in **styles.css**) — the `.3s`; closing is instant to keep the next song in view |
| Ink flecks: how many, what colors, off | `★ TWEAK: INK FLECKS` | Count + color list; delete the `setUpSparkles()` call at the bottom of the file to disable |
| The easter egg timing, or remove it | `★ TWEAK: EASTER EGG` | 5 clicks / 1.5s window / 1.6s glitch |
| Let multiple cards stay open at once | `★ TWEAK: ONE-AT-A-TIME` | Delete the marked `forEach` block |
| The copy-link button's label | `★ TWEAK: BUTTON TEXT` | Just the string |

---

## Recipes — timestamping and evidence

See [EVIDENCE.md](EVIDENCE.md) for the full workflow and first-commit line-ending migration.

- **New song:** run `./timestamp-songs.ps1`; commit the song, its current token, and its complete package in `timestamps/evidence/`.
- **Edited song:** run `./timestamp-songs.ps1 -Restamp`. The previous exact lyrics and proof remain in their package. A failed request does not replace the current proof.
- **Before publishing:** run `./check-before-publish.ps1`. Any missing, changed, or invalid evidence is a failure. Do not treat a certificate error as an edit.
- **Recovery copy:** use `backup-lyric-evidence.ps1`. The chosen `evidence/` folder is excluded from Git but is inside the website; use external/private storage for independent backup and keep private drafts outside the site.
- **Golden rule:** never edit an archived version. Timestamps bind exact bytes, including line endings.

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
| The Read the lyrics button | `index.html` / `styles.css` | `scroll-hint` |
| "YEAR · STATUS" chip styling | `styles.css` | `card-meta` |
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
