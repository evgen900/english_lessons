# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A static site of self-contained English lesson pages for a young learner ("Diana"). There is no build step, no framework, no package manager — every page is a single hand-authored `index.html` containing inlined CSS and JS. The site is served as plain files by nginx in a Docker container.

- `index.html` — landing hub linking to each lesson directory.
- `class_02/index.html`, `class_03/index.html` — full self-contained lessons.
- New lessons follow the pattern `class_NN/index.html` and get a card added to the root `index.html` hub.

## Run / preview

There is no dev server in the repo; just open the HTML directly or serve the directory statically. Examples:

```bash
xdg-open index.html              # open the hub locally
python3 -m http.server 8000      # then visit http://localhost:8000/
```

To reproduce the production image locally:

```bash
docker build -t english-lessons:dev .
docker run --rm -p 8080:80 english-lessons:dev
```

There are no tests, linters, or formatters configured — don't invent commands for them.

## Deployment

`.github/workflows/deploy-production.yml` runs on push to `main` (or via `workflow_dispatch`). It SSHes into the server defined by the `production` GitHub environment (`vars.DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_PORT`, `secrets.DEPLOY_KEY`), pulls the repo into `/opt/english-lessons`, builds the image, and restarts a container named `english-lessons` on port `7020` attached to the external `app` Docker network. `docker-compose.production.yml` exists for manual server use and reads its values from environment variables (`APP_CONTAINER_NAME`, `APP_PORT`, `APP_NETWORK`) — the GitHub workflow does not use it; it runs `docker build` + `docker run` directly.

The `Dockerfile` simply copies the repo into `nginx:alpine`'s html root, so any file committed to the repo is served verbatim. `.dockerignore` excludes `.git`, `.github`, the Dockerfile itself, and `.dockerignore`.

## Lesson page architecture

Each `class_NN/index.html` is a single-page app that walks the learner through ordered sections. The shared shape:

- A fixed top bar with a `progress-steps` row of dots and a stars/score counter.
- A series of `<section class="section" id="...">` blocks; only one is `.active` (i.e. visible) at a time. Class 02 IDs are `s0`…`s6`; class 03 uses semantic IDs like `sec-welcome`, `sec-theory`, `sec-builder`, `sec-match`, `sec-story`, `sec-detective`, `sec-transform`, `sec-victory`.
- A `goTo(n)` function (defined inline in each lesson) toggles `.active`, updates the progress dots, and scrolls. Section navigation is the central control flow — when adding a new activity, hook it into the existing `SECTIONS`/`TOTAL_SECTIONS` list and the dot rendering, rather than introducing a new navigation mechanism.
- A reward loop: small interactions (selecting a card, completing a puzzle) call `addStar` / `updateScoreDisplays` and trigger toasts (`showToast`) and effects (`burst`, `launchConfetti`, ripple, particle canvas).
- Visual layer: an `aurora` blob background, a twinkling stars layer, and a full-screen `<canvas id="particleCanvas">` driven by an animation loop. These are decorative — keep them cheap and non-blocking.
- Shared design tokens via CSS custom properties (`--hot`, `--sun`, `--violet`, `--sky`, `--lime`, `--mint`, `--bg1`, `--bg2`, `--glow-*`) plus the Boogaloo / Fredoka One / Nunito web fonts loaded from Google Fonts. The hub page (`index.html`) intentionally mirrors these tokens so the lessons feel like one site — preserve the palette and font stack when adding pages.

State is kept in plain module-scope variables (`cur`, `stars`, per-activity arrays). There is no persistence — refreshing the page resets progress. Don't add `localStorage` or a framework unless explicitly asked; the simplicity is the design.

## Editing conventions

- Keep each lesson page self-contained: inline its CSS and JS, don't extract shared assets across lessons. Two lessons duplicating a helper is fine; a shared file would force a build step this repo doesn't have.
- When adding a lesson, copy the closest existing `class_NN/index.html` as the starting template, then add a matching card to the root `index.html` (lesson badge, icon, chips, and a `./class_NN/` link).
- File paths in links are relative (`./class_02/`); keep them that way so the site works both behind nginx and when opened from disk.
