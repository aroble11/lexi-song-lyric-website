# Lexi Notebook

Custom, reusable title lettering created for Lexi Robles from the visual direction of `design-mockups/01-personal-lyric-notebook.png`.

This is a newly drawn interpretation of the mockup, not an extracted font or an exact reproduction of every generated letter. No outlines from The Nautigal or another third-party font were copied. The artist-name image remains separate.

## Files and use

- `LexiNotebook-Regular.ttf`: installable regular weight, for collection titles.
- `LexiNotebook-Bold.ttf`: installable bold weight, for the featured song.
- Matching `.woff2` files: compact versions loaded by the website.
- `preview.html`: interactive specimen; type a future song title to compare weights.
- `build_font.py`: editable vector source and reproducible font builder.

Both weights belong to the **Lexi Notebook** family, with weights 400 and 700. The slant is built into the letterforms; use normal font style, not an additional italic transformation. New songs inherit their weight from `.card-title` and `.featured-card .card-title` automatically. The sidebar remains in the reading font. Text remains selectable and accessible.

Each file maps 156 characters: basic Latin uppercase/lowercase, digits, ASCII punctuation, smart quotes, en/em dashes, ellipsis, nonbreaking space, and common precomposed Latin accented letters including Spanish vowels and ñ. This is a title font, not a full multilingual text family; unsupported characters use the site's fallback fonts. It has fixed handwritten forms, not contextual alternates or a variable-font axis. Lowercase connecting strokes share their entry/exit height. Both weights use the same advances, avoiding layout changes when switching weight.

The regular weight emphasizes light connections; the bold weight adds pressure to downstrokes. The underline beneath the featured title is a CSS decoration and is not baked into the font.

## Reuse

These original project assets may be used, installed, embedded, copied, and modified for Lexi's website, future songs, and other projects. There is no third-party font attribution requirement for these files. The separate legacy fonts retain their own licenses.

## Rebuild

Requires Python 3 and `fonttools==4.67.0`, `shapely==2.2.0`, `brotli==1.2.0`. Install them into your preferred development environment, then run:

```powershell
python fonts/lexi-notebook/build_font.py
```

For dependencies installed using `pip --target`, append `--deps PATH`.
These are build-only dependencies; the website remains plain HTML/CSS/JavaScript.

Centerlines are hand-authored cubic/quadratic paths. The builder samples the curves, applies slant and direction-dependent stroke pressure, unions outlines, and creates TrueType and WOFF2 files using [fontTools FontBuilder](https://github.com/fonttools/fonttools/blob/main/Lib/fontTools/fontBuilder.py). Both formats are reopened to validate their character maps, weight metadata, and vertical bounds. Fonts are intended for title-size display; inspect the specimen after editing outlines.
