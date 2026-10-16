# Preparing and publishing the site

## Current local preparation

`prepare-site.ps1` verifies every current song and archived proof, then copies only approved public files into a new `_site/` folder. `publish-files.json` lists the page, styles, scripts, images, fonts, and bundled font licenses. Songs are taken from `songs.js`. The copied lyric bytes are checked against their signed fingerprints again.

Backups, timestamp packages, drafts, mockups, Git metadata, font-building tools, and project documentation are not included in the Pages artifact. Evidence still belongs in version control; excluding it from the website does not make files in a public GitHub repository private.

Run locally with:

```powershell
.\prepare-site.ps1
```

The destination must not already exist. For another preview, choose a fresh folder, for example `-OutputDirectory '_site/review-2'`. The tool never clears or overwrites an existing folder. A failed run may leave an incomplete output; only a successful run is eligible for deployment.

When adding artwork or fonts, add their public paths to `publish-files.json`. References in HTML, CSS, and JavaScript are checked so the dynamically inserted rose and heart cannot silently be omitted. Font license files are retained. No recursive copy of the repository is used.

## Git byte preservation

The original timestamp proofs match CRLF lyric files. The older committed Git versions use LF. `.gitattributes` disables normalization for songs and evidence. The local preparation stages that rule and re-adds the tracked songs with `git add --renormalize songs/`, preserving their actual bytes without changing their wording or rewriting timestamps.

Include these staged changes together with the redesigned site, evidence packages, scripts, manifest, tests, and workflow when preparing the release commit. Staging is local; it does not commit, push, or publish. The rest of the existing working changes remain available for review. A later checkout must pass `check-before-publish.ps1` before it can produce an artifact.

## Workflow behavior

`.github/workflows/verify-lyric-evidence.yml` is named **Validate and publish site**:

- Pushes to `main` and pull requests run the packaging tests and verify/prepare the site. They do not deploy through this workflow.
- A manual run defaults to **Publish: false**, so it also checks without deploying.
- A manual run from `main` with **Publish: true** uploads only `_site/` and deploys it after `verify-and-package` succeeds.
- The deployment job depends on that verification job using `needs`. Failed checks or tests prevent artifact upload and deployment. Write permissions are limited to the deployment job.

## Activation is a separate release action

The owner confirmed switching **Settings > Pages > Build and deployment > Source** to **GitHub Actions** during release preparation. The workflow has not yet run on GitHub. Keep that source selected: reverting to branch-based publishing would bypass this workflow and could publish a pushed commit without this gate.

When release is authorized, switch the publishing source first, commit and push the reviewed files, confirm the validation run is green, then run **Validate and publish site** manually from `main` with **Publish: true**. Do not use the old branch-based publishing instructions.

The `github-pages` environment can have additional branch/reviewer protection configured in GitHub. Those settings are not changed by this preparation.

References: [GitHub Pages custom workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages), [git add --renormalize](https://git-scm.com/docs/git-add).
