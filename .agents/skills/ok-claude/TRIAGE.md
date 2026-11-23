# Triage

Decide whether an agent can implement the issue, following the installed plugin's `triage` skill ("Triage a specific issue or PR") with these changes for an unattended run:

- **Recommend, then decide.** Don't wait for direction after step 2: make the call yourself.
- **Verify** as the skill says (reproduce a bug where you can; the environment can run the app and specs). Verify a screen reader report with the `screen-reader-bug` skill.
- **Don't grill.** Questions you would have asked the maintainer go into the `human please` comment instead.
- **Don't close the issue or write to `.out-of-scope/`**, whatever the outcome, and don't mention `.out-of-scope/` in comments.
- **Earlier triage**: if the issue has triage comments from an earlier run, follow the skill's "Resuming a previous session": read the answers given since, and don't re-ask what's resolved.

Map the outcome with the triage labels in AGENTS.md ("Agent skills"):

- **`ready-for-agent`**: the issue's text (with its comments, later ones taking precedence, as AGENTS.md says) is enough for an agent to implement it without coming back with questions. Post an agent brief (the skill's `AGENT-BRIEF.md`) when the issue isn't already clear enough on its own, e.g., when its comments changed the scope or the acceptance criteria are implicit. Then replace `ok claude : on it` with `ok claude : implement`, which starts implementation.
- **Anything else** (`needs-info`, `ready-for-human`, `wontfix`): post a comment with a one- or two-sentence explanation of why a person is needed (a judgement call, design decision, missing information, outside access, manual testing, or a recommendation not to do it), then the questions a person should answer, if any, as a numbered list, each specific enough to answer in a line or two. Then replace `ok claude : on it` with `ok claude : human please`.

Don't change the issue's project board Status.
