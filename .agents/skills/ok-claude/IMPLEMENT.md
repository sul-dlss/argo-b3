# Implement

Implement the issue and open a pull request, following the installed plugin's `implement` skill for the one issue, with these changes for an unattended run:

- **The spec** is the issue's text with its comments, an agent brief if there is one, as AGENTS.md describes ("When implementing an issue, …"). Read the issue's screenshots and Figma links too (the Figma connector is available).
- **Branch**: `claude/<issue number>-<short-slug>`, from `main`.
- **Checks before opening the PR**: `bin/rake lint` reports `LINT OK`, and the specs relevant to the change pass (`bin/rspec <files>`, or `bin/parallel_rspec` for broad changes). If you can't get there, don't open a PR (see "When you can't finish").
- **Code review**: run the `code-review` skill as `implement` says, and fix what it finds before opening the PR.

## Open the PR

Follow the repo's `pull-request` skill ("Opening a draft PR"), with these changes:

- **Not a draft**: create it with `create_pull_request` and `draft: false`, base `main`. Don't wait to be asked to post the body or the inline comments: post them.
- **Screencast**: this session can't attach files to a PR, so the dispatcher attaches them. For a user-facing change, capture the video or screenshots with the `screencast` skill, then, before labelling the PR:
  1. Push the files, and only them, at the top level of a new orphan branch `claude/pr-media/<PR head branch>`.
  2. Reference each in the PR body by bare filename, as the `pull-request` skill says (`![<alt>](./<file>)`).
  When the PR is labelled `ok claude : ready for dev review`, the dispatcher uploads the files into the body in place of those references and deletes the media branch. If it can't, it comments on the PR and leaves the branch.
- **Provisional decisions** matter most here, since no one answered planning questions: list every judgement call you made, each on the matching list.
- **Merge Danger**: include the integration-spec reminder from AGENTS.md when it applies.
- **Inline comments**: post them as one review, with the session's review tools, ending each with "Created by Claude."
- Label the PR `ok claude : ready for dev review`, last of these steps.

Then:

1. Subscribe to the PR's activity (`subscribe_pr_activity`). While this session lives, address new review comments and CI failures as they arrive, following [ADDRESS-REVIEW.md](ADDRESS-REVIEW.md) without its label changes.
2. On the issue, replace `ok claude : on it` with `ok claude : ready for dev review`. (The dispatcher moves the issue to In review on the project board.)

## When you can't finish

Examples: a question the spec doesn't answer, lint or specs you can't make pass, or work much larger than the issue suggests.

1. Commit and push what you have to the `claude/` branch, if anything.
2. Comment on the issue: one or two sentences on what stopped you, the questions a person should answer (numbered), and a link to the branch.
3. Replace `ok claude : on it` with `ok claude : human please`.
