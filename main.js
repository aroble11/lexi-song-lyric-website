/* ============================================================
   main.js — BUILDS THE LYRIC CARDS
   ============================================================
   You should not need to edit this file to add songs — that
   happens in songs.js and the songs/ folder. This file is here
   if you're curious how it works, or want to change behavior.

   THE WHOLE FLOW, IN PLAIN WORDS:
     1. songs.js (loaded before this file) gave us a list called
        SONGS of text filenames inside the songs/ folder.
     2. For each filename, we download the file with fetch().
     3. Each file is split into a small "header" (the Title:,
        Year:, Status: lines at the top) and the lyrics (every-
        thing after the first blank line).
     4. We build one clickable card per song and put it in the
        #lyrics-grid container in index.html.
     5. Clicking a card expands it in place to show the full
        lyrics; clicking again collapses it. (The open/close
        animation itself lives in styles.css.)

   SAFETY NOTE: lyrics are always inserted with .textContent,
   never .innerHTML. That means characters like < > & " in your
   lyrics are shown literally and can never break the page.
   ============================================================ */

"use strict";

/* ------------------------------------------------------------
   STEP 1 — parse one song file's text into a usable object.

   A song file looks like:

       Title: Neon Veins        <- header: "Key: Value" lines
       Year: 2026
       Status: finished
                                 <- FIRST BLANK LINE ends header
       [Verse 1]                 <- everything below is lyrics
       We were static on a dead channel...

   Returns an object like:
       { title: "Neon Veins", year: "2026",
         status: "finished", lyrics: "[Verse 1]\n..." }
   ------------------------------------------------------------ */
function parseSong(rawText, filename) {
  // Normalize Windows line endings (\r\n) to plain \n so the
  // rest of the code only has to think about one kind.
  const text = rawText.replace(/\r\n/g, "\n");

  // The header is everything before the first blank line.
  const blankLineAt = text.indexOf("\n\n");
  const headerPart = blankLineAt === -1 ? "" : text.slice(0, blankLineAt);
  const lyricsPart = blankLineAt === -1 ? text : text.slice(blankLineAt + 2);

  // Read the "Key: Value" lines from the header into an object.
  const header = {};
  for (const line of headerPart.split("\n")) {
    const colonAt = line.indexOf(":");
    if (colonAt === -1) continue; // not a Key: Value line, skip it
    const key = line.slice(0, colonAt).trim().toLowerCase();
    const value = line.slice(colonAt + 1).trim();
    header[key] = value;
  }

  return {
    // If there's no Title: line, fall back to the filename so
    // the card is never blank.
    title: header.title || filename.replace(/\.txt$/, ""),
    year: header.year || "",
    status: header.status || "",
    // Optional one-line "story behind the song", shown at the
    // bottom of the opened card if present.
    story: header.story || "",
    // A short, URL-friendly id used for share links like
    // yoursite.com/#example-song-one — it's the filename without
    // ".txt" and without the "01-" number prefix.
    slug: filename.replace(/\.txt$/, "").replace(/^\d+-/, ""),
    lyrics: lyricsPart.trim(),
  };
}

/* ------------------------------------------------------------
   STEP 2 — turn the lyrics text into styled lines.

   Each line of the lyrics becomes its own <span> so that:
     - line breaks are preserved exactly as you typed them
     - lines like [Chorus] (square brackets around the whole
       line) can be given their own accent style
   ------------------------------------------------------------ */
function buildLyricsElement(lyricsText) {
  const container = document.createElement("div");
  container.className = "lyrics-text";

  for (const line of lyricsText.split("\n")) {
    const lineEl = document.createElement("span");
    lineEl.className = "lyric-line";

    const trimmed = line.trim();
    if (trimmed === "") {
      // Blank line in the file = visual gap between sections.
      lineEl.classList.add("lyric-gap");
      lineEl.innerHTML = "&nbsp;"; // safe: a fixed non-breaking space, not user text
    } else if (/^\[.+\]$/.test(trimmed)) {
      // A section marker like [Chorus] — give it accent styling.
      lineEl.classList.add("section-label");
      lineEl.textContent = trimmed;
    } else {
      lineEl.textContent = line; // .textContent = always safe
    }

    container.appendChild(lineEl);
  }

  return container;
}

/* ------------------------------------------------------------
   STEP 3 — build one card for one song.

   The card structure we create here (all of it styled by
   styles.css):

     <article class="song-card">
       <button class="card-toggle" aria-expanded="false">
         <h2>SONG TITLE</h2>
         <p class="chips">2026 · finished</p>
         <p class="teaser">first couple of lyric lines…</p>
         <span class="expand-icon">+</span>
       </button>
       <div class="lyrics-panel">          <- animates open/closed
         <div class="lyrics-panel-inner">
           …the full lyrics…
         </div>
       </div>
     </article>

   Using a real <button> means keyboards (Tab + Enter/Space)
   and screen readers work without any extra code.
   ------------------------------------------------------------ */
function buildCard(song, index) {
  const card = document.createElement("article");
  card.className = "song-card";
  // The card's id IS the share link target: visiting the page
  // as ...#example-song-one finds this card and opens it.
  card.id = song.slug;

  // --- the clickable top part -------------------------------
  const toggle = document.createElement("button");
  toggle.className = "card-toggle";
  toggle.setAttribute("aria-expanded", "false");
  // Connects the button to the panel it controls (accessibility).
  toggle.setAttribute("aria-controls", "lyrics-panel-" + index);

  const title = document.createElement("h2");
  title.className = "card-title";
  title.textContent = song.title;
  toggle.appendChild(title);

  // The little "2026 · finished" chip line. Only shown if the
  // song file actually had Year/Status lines.
  const chipText = [song.year, song.status].filter(Boolean).join(" · ");
  if (chipText) {
    const chips = document.createElement("p");
    chips.className = "card-chips";
    chips.textContent = chipText;
    toggle.appendChild(chips);
  }

  // The teaser: the first 2 real lyric lines (skipping blanks
  // and [Section] markers), faded out, as a preview.
  const teaserLines = song.lyrics
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l !== "" && !/^\[.+\]$/.test(l))
    .slice(0, 2);
  if (teaserLines.length > 0) {
    const teaser = document.createElement("p");
    teaser.className = "card-teaser";
    teaser.textContent = teaserLines.join(" / ");
    toggle.appendChild(teaser);
  }

  // The +/× icon in the corner (rotates via CSS when open).
  const icon = document.createElement("span");
  icon.className = "expand-icon";
  icon.setAttribute("aria-hidden", "true"); // decorative only
  icon.textContent = "+";
  toggle.appendChild(icon);

  card.appendChild(toggle);

  // --- the expanding part with the full lyrics ---------------
  // Two nested divs is the trick that lets CSS animate the
  // height smoothly (see .lyrics-panel in styles.css).
  const panel = document.createElement("div");
  panel.className = "lyrics-panel";
  panel.id = "lyrics-panel-" + index;

  const panelInner = document.createElement("div");
  panelInner.className = "lyrics-panel-inner";
  panelInner.appendChild(buildLyricsElement(song.lyrics));

  // --- "the story behind the song" (optional) ----------------
  // Only appears if the song file has a Story: line in its header.
  if (song.story) {
    const story = document.createElement("div");
    story.className = "song-story";

    const label = document.createElement("p");
    label.className = "story-label";
    label.textContent = "// THE STORY";
    story.appendChild(label);

    const text = document.createElement("p");
    text.className = "story-text";
    text.textContent = song.story; // .textContent = always safe
    story.appendChild(text);

    panelInner.appendChild(story);
  }

  // --- the "copy link" button --------------------------------
  // Copies a direct link to this exact song (e.g. ...#neon-veins)
  // so you can share one song instead of the whole page.
  const actions = document.createElement("div");
  actions.className = "panel-actions";

  const copyBtn = document.createElement("button");
  copyBtn.className = "copy-link-btn";
  const copyLabel = "⧉ copy link to this song";
  copyBtn.textContent = copyLabel;

  copyBtn.addEventListener("click", (event) => {
    // Don't let this click bubble up and toggle the card.
    event.stopPropagation();
    const link =
      window.location.origin + window.location.pathname + "#" + song.slug;

    // Flashes "link copied!" on the button for a moment.
    const showCopied = () => {
      copyBtn.textContent = "✓ link copied!";
      setTimeout(() => { copyBtn.textContent = copyLabel; }, 2000);
    };

    navigator.clipboard.writeText(link).then(showCopied).catch(() => {
      // Older or locked-down browsers: fall back to the classic
      // invisible-textbox copy trick.
      const tmp = document.createElement("textarea");
      tmp.value = link;
      document.body.appendChild(tmp);
      tmp.select();
      document.execCommand("copy");
      tmp.remove();
      showCopied();
    });
  });

  actions.appendChild(copyBtn);
  panelInner.appendChild(actions);

  panel.appendChild(panelInner);
  card.appendChild(panel);

  // --- open/close behavior ----------------------------------
  toggle.addEventListener("click", () => {
    // Only one card may be open at a time: before toggling this
    // one, collapse any OTHER card that's currently expanded.
    document.querySelectorAll(".song-card.open").forEach((openCard) => {
      if (openCard !== card) {
        openCard.classList.remove("open");
        // Keep the collapsed card's button state honest for
        // screen readers too.
        openCard
          .querySelector(".card-toggle")
          .setAttribute("aria-expanded", "false");
      }
    });

    const isOpen = card.classList.toggle("open");
    // aria-expanded tells screen readers the current state.
    toggle.setAttribute("aria-expanded", isOpen ? "true" : "false");

    // Keep the address bar in sync: opening a song puts its
    // share link in the URL, closing it cleans the URL back up.
    // (replaceState changes the URL without scrolling the page.)
    if (isOpen) {
      history.replaceState(null, "", "#" + song.slug);
    } else {
      history.replaceState(
        null, "", window.location.pathname + window.location.search
      );
    }
  });

  return card;
}

/* ------------------------------------------------------------
   STEP 4 — load every song listed in songs.js and fill the grid.
   ------------------------------------------------------------ */
async function loadAllSongs() {
  const grid = document.getElementById("lyrics-grid");

  // Download all song files at the same time (faster than one
  // by one). Promise.all keeps the results in the same order
  // as the SONGS list, so the page order matches songs.js.
  const results = await Promise.all(
    SONGS.map(async (filename) => {
      try {
        const response = await fetch("songs/" + filename);
        if (!response.ok) {
          // The server answered but couldn't find/serve the file
          // (e.g. a typo'd filename in songs.js).
          throw new Error("HTTP " + response.status);
        }
        const text = await response.text();
        return { ok: true, song: parseSong(text, filename) };
      } catch (err) {
        return { ok: false, filename: filename, error: err };
      }
    })
  );

  let anyFailed = false;
  results.forEach((result, index) => {
    if (result.ok) {
      grid.appendChild(buildCard(result.song, index));
    } else {
      anyFailed = true;
      // Show a small error card so a typo in songs.js is easy
      // to spot instead of a song silently going missing.
      const errCard = document.createElement("article");
      errCard.className = "song-card error-card";
      errCard.textContent =
        "Couldn't load \"" + result.filename + "\" — check that the file " +
        "exists in the songs/ folder and the name in songs.js matches exactly.";
      grid.appendChild(errCard);
    }
  });

  // Special case: opening index.html by double-clicking it uses
  // the file:// protocol, where browsers block fetch() entirely.
  // Every song fails at once in that case, so explain the fix.
  if (anyFailed && window.location.protocol === "file:") {
    grid.innerHTML = ""; // replace the error cards with one clear note
    const note = document.createElement("article");
    note.className = "song-card error-card";
    note.textContent =
      "Heads up: browsers don't allow this page to load the song files " +
      "when it's opened directly from disk (file://). Preview it with a " +
      "local server instead — see \"Previewing locally\" in README. " +
      "On the live GitHub Pages site this works automatically.";
    grid.appendChild(note);
  }

  // If the page was opened through a song share link (an address
  // ending in #some-song), find that card, open it, and scroll
  // straight to it.
  const requested = decodeURIComponent(window.location.hash.slice(1));
  if (requested) {
    const target = document.getElementById(requested);
    if (target && target.classList.contains("song-card")) {
      target.classList.add("open");
      target
        .querySelector(".card-toggle")
        .setAttribute("aria-expanded", "true");
      target.scrollIntoView({ block: "start" });
    }
  }
}

/* ------------------------------------------------------------
   SITE-WIDE CURSOR GLOW
   A soft circle of light (the .cursor-glow div in index.html)
   follows the mouse everywhere on the page. All this code does
   is keep that div centered on the pointer — the look of the
   glow itself lives in styles.css.
   ------------------------------------------------------------ */
function setUpCursorGlow() {
  const glow = document.querySelector(".cursor-glow");
  if (!glow) return;

  // Only devices with a real mouse/trackpad get the glow.
  // (Phones and tablets skip it — a glow stuck wherever you
  // last tapped would just look like a smudge.)
  if (!window.matchMedia("(hover: hover) and (pointer: fine)").matches) return;

  document.addEventListener("mousemove", (event) => {
    // transform is the cheapest way to move something around —
    // the browser can do it without recalculating the layout.
    glow.style.transform =
      "translate(" + event.clientX + "px, " + event.clientY + "px)";
    // The glow stays invisible until the mouse actually moves,
    // so it never sits awkwardly in a corner on page load.
    glow.classList.add("active");
  });
}

/* ------------------------------------------------------------
   CLICK INK FLECKS
   A little spatter of ink wherever you click — or tap, on a
   phone ("pointerdown" covers mouse, touch, and pen). Each fleck
   is a tiny <span> that flies outward, shrinks, fades, and
   deletes itself when its animation ends. (The flecks fit the
   paper theme: mostly ink and charcoal, with the occasional
   speck of stamp-red or ochre.)
   ------------------------------------------------------------ */
function setUpSparkles() {
  const FLECK_COUNT = 8;
  // A little spray of blood: mostly crimson/oxblood, with the
  // occasional darker drop and a pale glass speck.
  const COLORS = ["#b3202b", "#6e2433", "#8a2a3c", "#2a1016", "#dfe6ea"];

  // People who've set their device to "reduce motion" get none.
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

  document.addEventListener("pointerdown", (event) => {
    if (reduceMotion.matches) return;

    for (let i = 0; i < FLECK_COUNT; i++) {
      const fleck = document.createElement("span");
      fleck.className = "sparkle";

      // Start exactly at the click/tap point...
      fleck.style.left = event.clientX + "px";
      fleck.style.top = event.clientY + "px";

      // ...vary the size a little so the spatter looks uneven...
      const size = 3 + Math.random() * 5;
      fleck.style.width = size + "px";
      fleck.style.height = size + "px";

      // ...and fly out in a roughly even circle, with a little
      // randomness in the angle and distance so no two spatters
      // look identical.
      const angle = (Math.PI * 2 * i) / FLECK_COUNT + Math.random() * 0.6;
      const distance = 16 + Math.random() * 24;
      fleck.style.setProperty("--dx", Math.cos(angle) * distance + "px");
      fleck.style.setProperty("--dy", Math.sin(angle) * distance + "px");

      // A neutral ink most of the time; a colored speck now and then.
      fleck.style.background = COLORS[Math.floor(Math.random() * COLORS.length)];

      document.body.appendChild(fleck);
      // Self-cleanup: remove the span once its animation is done.
      fleck.addEventListener("animationend", () => fleck.remove());
    }
  });
}

/* ------------------------------------------------------------
   EASTER EGG — click the big name in the hero 5 times, fast.
   main.js puts a "rockout" class on <body> for a moment and
   styles.css does a neon glitch freakout. Harmless fun; delete
   this whole block (and the .rockout styles) to remove it.
   ------------------------------------------------------------ */
function setUpEasterEgg() {
  const heroTitle = document.querySelector(".hero h1");
  if (!heroTitle) return;

  let clickCount = 0;
  let resetTimer;

  heroTitle.addEventListener("click", () => {
    clickCount++;
    // The clicks have to come quickly: pause too long between
    // them and the count starts over.
    clearTimeout(resetTimer);
    resetTimer = setTimeout(() => { clickCount = 0; }, 1500);

    if (clickCount >= 5) {
      clickCount = 0;
      document.body.classList.add("rockout");
      // The glitch lasts about a second and a half, then the
      // class comes off so it can be triggered again.
      setTimeout(() => document.body.classList.remove("rockout"), 1600);
    }
  });
}

// Kick everything off once the page's HTML has been parsed.
document.addEventListener("DOMContentLoaded", () => {
  loadAllSongs();
  setUpCursorGlow();
  setUpSparkles();
  setUpEasterEgg();
});
