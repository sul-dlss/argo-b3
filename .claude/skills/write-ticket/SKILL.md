---
name: write-ticket
description: Interview a product owner or designer about one ticket-sized idea, then write a complete, actionable ticket for it, or rewrite an existing ticket.
disable-model-invocation: true
---

# Write Ticket

The user is a product owner or designer with one ticket-sized idea: a feature, a change, or a bug from the user's point of view. Your job is to reach a shared understanding of **what** should happen and **why**, then write it down as a single ticket a developer can pick up without coming back with questions about behaviour. The idea may be new, or an existing ticket the user wants rewritten.

The user knows the domain and the users; you know the codebase. Use the code to make your questions concrete (what the page does today, which roles can see it, what labels it uses), but talk about behaviour, not implementation.

## 0. Check prerequisites

- If `mattpocock-skills:grilling` isn't among your available skills, stop. Tell the user to run `/plugin install mattpocock-skills@mattpocock`, restart Claude Code, and run this skill again.
- Run `gh auth status`. If `gh` is missing or not logged in, carry on without it: read referenced issues from their public page on GitHub, and in step 6 offer only Markdown to paste.

## 1. Gather the starting point

Work from what the user gave you: their description, any issue they reference (with `gh`, read it using `gh issue view <number> --comments`), and any screenshots. A screenshot may show the current UI, a mockup, or a bug; read it, and note what each one shows, since it will be placed in the ticket later.

**Rewriting an existing ticket**: read the issue and all its comments. Note what it already settles, what is vague or missing, and where the comments change or contradict the body. Images already in the issue are GitHub attachment URLs; try to view them, and if you can't, ask the user what each shows.

## 2. Learn the current behaviour

Before asking anything, find out how the area works today. Read `GLOSSARY.md` and the `README.md` sections for the area, then dispatch a sub-agent to explore the relevant code and report back in user-facing terms: which pages and forms are involved, what they show, who can use them (the policies), what happens on save, and what the related features do. Ask it for behaviour, not file listings.

Also have it find **similar features** elsewhere in the app: features that solve a comparable problem the new one should feel like (e.g., another bulk action, another edit form, another facet, another way of choosing a collection). For each, ask for the established pattern a user would notice: where it lives and how it's reached, its labels and wording, its controls, how it confirms success and reports errors, and who can use it.

This is what lets you ask 'the release form currently offers "Follow collection settings", "Release", and "Do not release"; should the new option sit beside those?' instead of 'what does the form look like?'. Facts about the system are yours to find; never ask the user something the code can answer.

Most user-visible behaviour is in this repo. When a question depends on another SDR service or gem (what DSA does on deposit or rejects on save, how a shared SDR View Components component behaves, how legacy Argo did it), read the local checkout named in `AGENTS.md` References if it exists; for a gem, try `bundle show <gem>`. Otherwise, explain to the user that you're fetching that repo's source to check, and shallow-clone it from `github.com/sul-dlss` into `${TMPDIR:-/tmp/}write-ticket-sources/<repo>`, reusing an earlier clone if there is one; for a gem, clone the tag matching its version in `Gemfile.lock`. If you still can't confirm the behaviour, don't guess and don't ask the user about another service's internals: list it under Assumptions to confirm in the ticket.

## 3. Check the scope

Assume the idea is one ticket. If it actually holds several independent topics (they could ship separately, or serve different users), say so, name each topic, and recommend splitting. Let the user choose: pick one topic to continue with now, or keep it as one ticket. Don't split on your own.

## 4. Grill

Invoke the `mattpocock-skills:grilling` skill and run its interview with this focus:

- **Ask about** who the user is and what they are trying to accomplish; where in the app this happens and how they get there; what they see and do, step by step; labels and wording; empty, error, and edge cases; permissions (who can and can't); what happens to existing objects and data; what is explicitly not included; how someone would check it works.
- **Don't ask about** classes, tables, jobs, gems, or how to build it. If a question only matters for implementation, leave it to the developer. If the code shows a behavioural consequence the user may not have thought of (e.g., the change also affects bulk actions, or admins already bypass this rule), raise that as a behaviour question.
- **Push for consistency** with the similar features from step 2. Where a decision has an established pattern, name the feature it comes from and recommend following it ("Other bulk actions show a confirmation with the number of objects affected; should this one too?"). If the user wants to depart from the pattern, ask why. A good reason belongs in the ticket; otherwise follow the pattern. If similar features disagree with each other, point out the inconsistency and ask which one to follow.
- **When rewriting**, start from the existing ticket: don't re-ask what it already settles clearly. Confirm a decision only if the code or the comments call it into question. Spend the rounds on its gaps, ambiguities and contradictions.
- Use the GLOSSARY vocabulary in your questions and recommendations, and correct gently when the user's term is ambiguous (e.g., "workflow step" is a **Process**).

The grilling ends when the user confirms you share an understanding, as the `grilling` skill describes.

## 5. Draft the ticket

Write the ticket in this shape:

```markdown
# <Title: the change, in the user's terms>

## What to build

<The end-to-end behaviour from the user's point of view: who, where, what they do, what happens. Two to four sentences or a few bullets. Include the why in a sentence when it isn't obvious.>

[Screenshot: <what it shows>]

## Acceptance criteria

- [ ] <One observable, checkable behaviour per line>
- [ ] ...

## Out of scope

- <Things discussed and deliberately excluded>

## Assumptions to confirm

- <Behaviour outside argo-b3 that couldn't be checked, for the developer to confirm>
```

- Keep it concise: a developer should be able to read it in a minute or two. Every decision from the grilling should be covered, but only state what a developer could otherwise get wrong. Leave out behaviour that stays as it is today, and anything already implied by "works like <feature>". Don't record the discussion or the alternatives you rejected.
- One short line per criterion. Merge criteria that say the same thing, and drop any that just restate What to build.
- Write criteria someone can verify by using the app: "A user who can't edit the object doesn't see the button", not "add a policy check".
- When the user chose to follow an existing feature, name it in What to build by its name in the app (e.g., "works like the Manage release form"), so the developer knows what to match. Record a deliberate departure, with its reason.
- No file paths, class names, or code: they go stale and pre-empt the developer's design.
- Put each `[Screenshot: ...]` placeholder where that image helps most, usually under What to build or beside the criterion it illustrates.
- Omit Out of scope if nothing was excluded, and Assumptions to confirm if everything was checked.
- When rewriting, keep the existing image Markdown (the attachment URLs still work after an edit), placed where each image helps most. When you show the draft, list anything from the original you dropped, so nothing disappears without the user agreeing.

Before showing the draft, reread it and cut anything a developer wouldn't miss. Then show it and revise until the user approves it.

## 6. Deliver

Ask the user which they want:

- **Create the GitHub issue**: run `gh issue create --title "<title>" --body-file <file>` in the current repo, and share the URL. If there are screenshot placeholders, tell the user that GitHub only accepts images through its web UI, so they need to edit the issue there and drag each image onto its placeholder.
- **Markdown to paste**: print the final ticket in a single code block, so they can paste it into GitHub's New Issue page and drop the screenshots in there.

When rewriting, offer **Update the existing issue** in place of creating one: run `gh issue edit <number> --title "<title>" --body-file <file>` and share the URL. GitHub keeps the issue's edit history, so the original body can still be seen. With Markdown to paste, the user pastes it in by editing the issue.

Without a working `gh` (step 0), skip the question and give the Markdown. Mention that installing `gh` (`brew install gh`) and logging in (`gh auth login`, in a separate terminal) would let the skill create the issue directly next time.
