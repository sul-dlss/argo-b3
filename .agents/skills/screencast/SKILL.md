---
name: screencast
description: Record a short captioned screencast of a web app feature with playwright-cli, verified frame by frame. Use when asked to record, capture, or demo a feature as a video, or when a pull request for a user-facing change needs one.
---

# Screencast

A screencast shows a reviewer the feature working without a checkout: 30–50 seconds, under 10 MB (GitHub's video limit on free plans), every **beat** visible.

**Prerequisites** (macOS or Linux):

- `playwright-cli` on the PATH; if `command -v playwright-cli` finds nothing, `npm install -g @playwright/cli`.
- Google Chrome, driven with `--browser=chrome`; if missing, `playwright-cli install-browser chrome` (on Linux, add `--with-deps`).
- `ffmpeg` and `ffprobe`; if missing, `brew install ffmpeg` (macOS) or the distro's package (e.g., `sudo apt install ffmpeg`).
- The app running locally from this checkout, with demo data. For argo-b3's local stack, port, and demo data, read [references/argo-b3.md](references/argo-b3.md).

**Isolation**: other sessions may be recording at the same time, each from its own checkout. Name the browser session after this checkout (`SESSION=$(basename "$PWD")`, then `playwright-cli -s="$SESSION" ...` in every command), and point the script at this checkout's server (`<app url>` below, e.g. `http://localhost:3001`).

## 1. Plan the beats

List the beats, in order:

- **Entry**: how a user reaches the feature (e.g., the button on the show page that is now enabled).
- **Happy path**: the main interaction, with realistic values.
- **Non-happy path**: at least one, e.g., submit with a required field blank, show the error, correct it; or the error state next to the success state.
- **Result**: the page after success (toast, updated values, status).

Done when each beat has one sentence saying what the viewer sees.

## 2. Stage the data

Create fresh records so every beat can run. A beat that saves or deposits changes its record, so each take needs its own. Note every record you create, for the clean-up report.

## 3. Rehearse the locators

Open a session (`playwright-cli -s="$SESSION" open --browser=chrome <url>`) and use `snapshot`, `find`, and `eval` to settle each locator. Common traps:

- **Name collisions**: a tab, a nav menu, and a submit button can all be named "Deposit". Use `{ exact: true }` and scope with `.and(page.locator('[type=submit]'))`.
- **Submits that navigate**: wait with `page.waitForURL(...)` alongside the click (`Promise.all`), not `waitForLoadState('networkidle')`.
- **Fields on hidden tabs**: activate the tab before filling, and confirm the value landed (`page.waitForFunction(...)`) before submitting.
- **Layout shifts after errors**: leaving a corrected field can clear its error and move the buttons; tab out and pause before clicking.

## 4. Record

Write the script to a file and run it with `playwright-cli -s="$SESSION" run-code --filename=script.js`. Navigate before starting the recording so it opens on a loaded page; pace with pauses long enough to read each caption.

```js
async page => {
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.goto('<app url>/<entry page>');
  await page.waitForLoadState('networkidle');

  try { await page.screencast.stop(); } catch (e) {}
  await page.screencast.start({ path: '/tmp/<feature>/<feature>-demo.webm', size: { width: 1280, height: 800 }, fps: 30 });
  await page.screencast.showActions({
    duration: 500,
    style: { point: 'width: 18px; height: 18px; border-radius: 50%; background: rgba(255, 0, 0, .6)', title: 'display: none' },
  });

  const caption = (text, duration = 2000) => page.screencast.showOverlay(`
    <div style="position: absolute; top: 12px; left: 50%; transform: translateX(-50%);
      padding: 8px 16px; background: rgba(0,0,0,0.78); border-radius: 8px;
      font: 600 16px system-ui, sans-serif; color: white;">${text}</div>`, { duration });

  await caption('<entry beat>');
  await page.waitForTimeout(1500);
  // ... one block per beat: caption, act, pause ...

  await page.screencast.stop();
}
```

To point at an element, draw a box from its `boundingBox()` with `showOverlay` (overlays ignore pointer events, so the page stays clickable).

## 5. Verify

1. `ffprobe -v error -show_entries format=duration -of csv=p=0 <video>` for the length; check the file size.
2. Build contact sheets, nine frames each: `ffmpeg -v error -i <video> -vf "fps=1/2.5,scale=640:-1,tile=3x3" frames/sheet%02d.png`. For a detail too small to read, extract that one frame at full size: `ffmpeg -v error -ss <seconds> -i <video> -frames:v 1 frames/at<seconds>.png`.
3. Inspect every frame on every sheet: what's shown, the caption, and anything mid-load, cut off, left over from an earlier step, or covered by a caption. If a frame can't be viewed, say so rather than assume.

Re-record until every beat appears in at least one frame and nothing obscures it. Done when that holds, the video is 30–50 seconds, and it is under 10 MB.

## 6. Clean up and report

Close the browser session (`playwright-cli -s="$SESSION" close`) and stop the servers you started (for argo-b3, see the reference). Report the video's path and length, and every record you created that remains.
