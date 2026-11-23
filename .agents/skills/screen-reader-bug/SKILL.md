---
name: screen-reader-bug
description: Diagnose and fix what a screen reader announces. Use when an issue reports VoiceOver or another screen reader saying something wrong, missing, or extra, or when writing a ticket for one.
---

# Screen reader bugs

A screen reader announces what the browser exposes in its accessibility tree. VoiceOver runs only on macOS, so work from Chrome's tree, which Selenium system specs can read anywhere with the helpers in `spec/support/accessibility_tree_helpers.rb`:

- `accessibility_tree(selector)`: the subtree as indented lines (`role "name" states`), for exploring.
- `accessibility_node(selector)`: one element's role, name, description, properties, and child roles, for assertions.
- `click_listener_elements(selector)`: the element and its ancestors below `<body>` that listen for clicks.
- `event_listener_sources(expression)`: each listener on an element, `document`, or `window`, with the source that added it.

## What a report needs

1. The page, the element, and the steps that reach the state.
2. The exact words announced (VoiceOver's VO-Shift-C copies its last phrase) and the words expected.
3. The screen reader, the browser, and their versions.
4. Whether it also happens elsewhere, e.g., in other tables.

## Steps

1. **Pin down the report.** Done when each item in "What a report needs" is known or written down as a question. Carry on with questions open: the versions matter only if step 7 is reached.
2. **Reproduce** in a throwaway JS system spec. Copy the setup from the page's existing system spec (stubs at Solr and DSA), visit the page, reach the state, and print `accessibility_tree` for the region around the element. Done when you have the tree for the element the report names.
3. **Translate** the announcement into the tree. Each part of what VoiceOver says comes from one part of a node:
   - **Role**: the kind of thing ("button", "heading level 2", "table, 5 columns"). "list, 1 item" is a list role, e.g., a `<ul>` holding a cell's only value.
   - **Name**: the label, `aria-label`, `alt`, or text content.
   - **States**: properties such as expanded ("collapsed"), checked, pressed, selected, disabled ("dimmed"), required, invalid.
   - **Description**: `aria-describedby` targets such as help text, or `title`.
   - **Actions**: "clickable" means the element has its own click, mousedown, or mouseup listener (`click_listener_elements`). Safari also says it for text whose ancestor below `<body>` has one, when the text shows a pointer cursor; Chrome on macOS ignores ancestors.

   Done when every announced word is explained by a node, or it's clear none explains it.
4. **Check what the tree can't show** when the report is about something happening:
   - **Focus** after an action (DESIGN_STANDARDS A11Y-5): `page.evaluate_script('document.activeElement.outerHTML')`.
   - **Live regions** (A11Y-7, A11Y-8): the `role="status"` or `role="alert"` element is in the page before the change, and its text changes. A region inserted with its text already in it is often not announced.
   - **Reading order**: the tree follows DOM order, not visual order.
5. **Trace** the cause to its code. For markup, search `app/components` and the SDR View Components source for its classes and attributes. For a listener, `event_listener_sources` shows the script's opening (often a library banner, e.g., Turbo) and the code around it.
6. **Fix and test.** Turn the throwaway spec into a system spec that asserts on `accessibility_node` (or focus). Done when it fails without the fix and passes with it. A problem in an SDR View Components component is fixed there, in its own PR.
7. **When the tree doesn't explain the report**, stop guessing. Chrome's tree can differ from Safari's, and browser source can settle a mapping: WebKit's `Source/WebCore/accessibility`, Chromium's `third_party/blink/renderer/modules/accessibility` and, for macOS, `ui/accessibility/platform`. Report what you checked (the tree, the listeners, any browser source), the report's open questions, and a request for someone on a Mac to listen with VoiceOver in the reporter's browser. In an ok-claude run, that is a `human please` outcome.

When a fix can be confirmed only with VoiceOver in Safari, say so in the PR's provisional decisions.
