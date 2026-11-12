---
name: pull-request
description: Open a draft pull request that carries a screencast, provisional decisions, and inline reviewer comments, or address a review of one. Use when asked to put up, open, or draft a PR, or to address or reply to review comments.
metadata:
  credits: "Summary / Evidence / Merge Danger body adapted from the show-me skill by Dex Horthy (HumanLayer), https://github.com/humanlayer/skills"
---

# Pull requests

Everything this skill produces is visible to others under the user's name. Draft the PR body, inline comments, and review replies; post each one when the user asks for that step, then share its link.

## Opening a draft PR

1. **Screencast**: for a user-facing change, record one with the `screencast` skill. Backend-only changes and refactors skip it.
2. **Commit, then push, then create**: run them one after another. `gh pr create` fails with "No commits between main and …" when it runs before the push lands.
3. **Write the body** from the template below, in a file (e.g., `/tmp/<feature>/pr-body.md`) next to the video.
4. **Create the PR**: `gh pr create --draft --base main --head <branch> --title "<title>" --body-file pr-body.md --attach ./<video>.webm`, run from the directory holding both files. Reference the video in the body as `![<alt>](./<video>.webm)` so `gh` (2.99 or later) places it inline. Confirm with `gh pr view <N> --json isDraft,body` that it is a draft and the body has a `user-attachments` URL.
5. **Inline comments**: post them as one review (below).
6. **Report**: the PR link, the decisions flagged, and what the inline comments cover.

### Body template

```markdown
Closes #<issue>

## Summary

<What changed, from the user's side, in two or three sentences.>

![<feature> walkthrough](./<video>.webm)

### Approach

<The smallest sketch that shows the shape: a diff of the file tree or a call tree.>

### Provisional decisions and open questions (feedback welcome)

1. **<Decision, in a few words>.** <What was chosen, the alternative, and why.> <A question, when the choice is the reviewers' to make.>

## Evidence

- **Before:** <the old behaviour>
  **After:** <the screencast, plus each spec added or changed and what it covers>
- <Lint and test results. Name anything not run, and who will run it.>

## Merge Danger

**Door:** <one-way or two-way>

**Blast Radius:** <one word>

<What else could break, and any integration spec to run before merging (see AGENTS.md).>
```

**Provisional decisions** is the section reviewers rely on most. List every:

- answer the user gave to a planning question that a reviewer might decide differently;
- disagreement between the issue and its design, and every design element left out (see AGENTS.md);
- assumption made without asking;
- known problem left unfixed, and why.

Done when each appears, with its alternative.

### Inline comments

Choose the lines where a reviewer would ask "why this way?": a pattern chosen over an existing alternative, code moved or extracted (say whether it is a pure move), a deliberate deviation from the issue or design, security-relevant parameter handling, a spec workaround. Each comment explains the reasoning, which the diff can't show, in two to four sentences. End each newly authored comment with "Created by <agent name>.", using the identity of the agent actually writing it (for example, Codex writes "Created by Codex."). Do not copy another agent's name from examples or earlier comments, or guess an unavailable model name or version. Preserve the attribution on quoted or reused comments.

Comments must sit on a right-side line inside the diff: take line numbers from the head commit (`grep -n` on the pushed files). Post all of them as one review:

```shell
gh api repos/{owner}/{repo}/pulls/<N>/reviews --input - <<'EOF'
{"event": "COMMENT", "body": "Notes on implementation choices, to help with review.",
 "comments": [{"path": "app/forms/example_form.rb", "line": 17, "side": "RIGHT", "body": "<Reasoning for this choice>\n\nCreated by <agent name>."}]}
EOF
```

## Addressing a review

1. **Read** every review and comment from the reviewer: `gh api repos/{owner}/{repo}/pulls/<N>/reviews` and `.../pulls/<N>/comments --paginate`, then the code each comment is on. Check terminology against `GLOSSARY.md`.
2. **Pull** (`git pull --rebase`) before changing anything: others, including bots, may have pushed to the branch. Note anything they changed that bears on the PR's decisions.
3. **Change** what each comment asks. When a request conflicts with an earlier decision, ask the user. Run the linters, and the specs unless the user has said otherwise.
4. **Commit and push**, naming the review in the commit message.
5. **Reply in each thread**: `gh api repos/{owner}/{repo}/pulls/<N>/comments/<comment id>/replies -f body="..."`. Say what changed, with the commit SHA, and anything not done, with why.

Done when every thread has a reply and the user has the commit SHA.
