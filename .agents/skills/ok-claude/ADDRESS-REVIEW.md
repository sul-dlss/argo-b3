# Address review

Address the PR's unresolved review comments, following the repo's `pull-request` skill ("Addressing a review"), with these changes for an unattended run:

- **Comments to address**: unresolved review threads and review bodies written by people. You post as the workflow owner's GitHub user, who may also be a reviewer, so tell your own comments apart by the AI note they start with (or "Created by Claude." at the end), not by author. Read them with `pull_request_read`.
- **Pull first**, as the skill says: work on the PR's head branch, which may have commits from others.
- **Checks**: `bin/rake lint` reports `LINT OK` and the relevant specs pass before you push.
- **Replies**: reply in each thread with the session's reply tool, saying what changed and the commit SHA. Resolve the thread when the comment was unambiguous and fully addressed; leave it open otherwise.
- **A comment that needs a person's decision** (it conflicts with the issue or an earlier decision, or is ambiguous): don't guess. Reply in the thread with the question, address the rest, and end with `human please`.

Then, on the PR:

- If every comment was addressed: replace `ok claude : on it` with `ok claude : ready for dev review`.
- Otherwise: comment on the PR listing the questions, then replace `ok claude : on it` with `ok claude : human please`.
