# Design Standards

Rules for how Argo B3 looks, reads, and behaves, used to review new designs (mockups, issue descriptions) as well as code. Rules are stated by what a user sees; the *Use* notes say how to build it.

- **MUST** rules block a merge. **SHOULD** rules allow an exception when the reason is given in review.
- Rules marked *(linted)* are enforced by `bin/rake lint` (herb); reviewers skip them. All other rules are checked in review.
- New code that deliberately deviates from a rule has a comment beginning `Design standard deviation:` that names the rule and the reason. Existing code predates this standard and may deviate without a comment; when a change touches it, flag the deviation in review as a judgement call (fix it while you're there), not a blocker.

## Sources and precedence

When sources disagree, the higher one wins:

1. WCAG 2.2 level AA.
2. [SDR View Components](https://github.com/sul-dlss/sdr_view_components) (`SdrViewComponents::*`).
3. The [DLSS component library](https://github.com/sul-dlss/component-library) (`sul.css`): fonts, colors, typography.
4. Bootstrap 5 defaults.
5. The Argo B3 conventions in this document.

- **SRC-1 MUST** Use the SDR View Components component for an element whenever one exists (headings, buttons, form fields, fieldsets, tables, alerts, toasts, tabs, cards, spinners, horizontal rules, icon buttons). Raw Bootstrap markup is allowed only where the gem has no equivalent.
- **SRC-2 MUST** Where the gem has no equivalent (e.g., badges, pagination, description lists, facets, date fields), use or add a shared component under `app/components/elements/` rather than one-off markup. Note such components as candidates to move into the gem.

## Consistency

- **CONS-1 SHOULD** A function similar to one Argo B3 already has uses the same UI: the same components, layout, element choices, and wording. Before designing, find the existing UI for the nearest function (e.g., a new bulk action follows the other bulk action forms; a new history list follows the bulk action and Multi-Item Deposit history lists; choosing items from the last search or a druid list reuses `BulkActions::SelectSourceComponent`; a row of counts or statuses reuses `Show::BoxComponent`, as on the object and bulk action show pages). Explain any difference in review.
- **CONS-2 SHOULD** Reuse the existing UI by sharing its component rather than copying its markup, so the two stay alike as they change.
- **CONS-3** Consistency never overrides a written rule: if the existing UI breaks this standard, follow the standard, and fix the existing UI where practical. If a new design improves on an existing pattern, update the existing UI too where practical.

## Accessibility

All pages, including staff-only and form pages, MUST conform to WCAG 2.2 level AA. The rules throughout this document cover the criteria Argo B3 most often meets or misses; WCAG remains the authority for anything they don't cover.

### Keyboard and focus

- **A11Y-1 MUST** Everything that can be done with a mouse can be done with a keyboard, in a logical tab order. Clickable non-interactive elements (e.g., a `<tr>` with `data-bs-toggle`) are not keyboard operable; put a `<button>` inside instead.
- **A11Y-2 MUST** The focus indicator is never removed or restyled to be invisible.
- **A11Y-3 MUST** A focused element is not hidden by fixed or sticky content (e.g., the toast container) (WCAG 2.4.11).
- **A11Y-4 MUST** Pointer targets are at least 24×24 CSS px, or have equivalent spacing (WCAG 2.5.8).
- **A11Y-5 MUST** After an action that changes the page in place (adding or removing a row, a validation error without reload), focus moves somewhere sensible (e.g., to the error, the new row, or the control that replaced the removed one), never to the top of the page.
- **A11Y-6 MUST NOT** nest interactive elements (e.g., a link inside a button, a button inside a heading's link).

### Announcements

- **A11Y-7 MUST** Errors that appear without a page load (e.g., dropzone upload errors, Globus errors) are in an element with `role="alert"` so they are announced.
- **A11Y-8 MUST** On a page that refreshes itself (e.g., registration progress, Multi-Item Deposit status, bulk action status), status changes are in a polite live region (`role="status"`).

### Images and color

- **A11Y-9 MUST** Every `<img>` has `alt`; decorative images (e.g., thumbnails next to a title) have `alt=""`. *(linted)*
- **A11Y-10 MUST** Color is never the only way information is conveyed (e.g., an object-type badge shows its type as text; an error shows text or an icon, not only red).

## Page structure

- **PAGE-2 MUST** Every page sets a title that identifies it, with `page_title`, matching its h1. A page about one object or named record whose h1 doesn't name it (e.g., "Manage files") passes the name: "Manage files – <title>". The layout adds "| Argo B3"; a page that relies on the layout's fallback "Argo B3" alone fails.
- **PAGE-3 MUST** Every page has exactly one `<h1>`, describing the page (e.g., the object's title, "Register multiple items").
- **PAGE-4 MUST** A page below a top-level page has a back link at the top (`Elements::BreadcrumbComponent`): "← " followed by the name of the parent page (e.g., "← Workgroup permissions"), never just "Back". A page with a Cancel action does not need one.
- **PAGE-5 MUST** Landmarks are used for their purpose: navigation in `<nav>` (not `div role="navigation"`), and when a page has more than one `<nav>`, each has a distinct `aria-label`.

## Headings

- **HEAD-1 MUST** Heading levels are not skipped (h1 → h2 → h3), in DOM order.
- **HEAD-2 MUST** Headings are real `<h1>`–`<h6>` elements, rendered through `HeadingComponent`. Use `Elements::DivHeadingComponent` (`role="heading"`) only where a heading element would be invalid HTML.
- **HEAD-3 MUST** Visual size is set with `HeadingComponent`'s `variant:` (e.g., an h2 styled as `h4`), never by choosing a different level. Conversely, text that is styled as a heading (`class="h3"`) and introduces a section is a heading element.
- **HEAD-4 MUST** Headings contain only text. Controls (e.g., the pin button), badges (e.g., "Read only"), and icons that suggest an action go beside the heading, not inside it.
- **HEAD-5 MUST NOT** have empty headings. *(linted)*

## Layout and spacing

- **LAY-1 MUST** Page content is in `Layout::ContainerComponent` (a `container py-2`), which also renders the page's breadcrumb, h1, and subtitle when given them. Two-column pages (LAY-5) render their own h1 inside it.
- **LAY-2 SHOULD** Use these spacings so pages share a rhythm:
  - h1: `mb-3` (`Layout::ContainerComponent` applies it; with a subtitle, the subtitle gets `mb-3`).
  - Between page sections: `mb-5`.
  - Form fields: `my-field`; fieldsets: `my-fieldset` (applied by `.b3-form` / `.tab-form`, see FORM-1).
  - Form footer: `mt-5`.
- **LAY-3 MUST NOT** use inline `style` attributes for spacing, widths, or z-index; use utilities or a class in app SCSS.
- **LAY-4** Breakpoints and devices:
  - `xxl`, `xl`: monitor. `lg`, `md`: tablet. `sm`, `xs`: phone.
  - **SHOULD** Show pages (e.g., dashboard, object page, search) work at all three sizes. Form pages (e.g., registration, edit, bulk actions) are designed for monitors.
  - **MUST** Every page, including form pages, reflows at 400% zoom (320 CSS px wide) without horizontal scrolling, except content that needs two dimensions (tables, the workflow grid, the structure editor) (WCAG 1.4.10).
- **LAY-5** The dashboard, object page, and bulk action page use `Structure::TwoColumnWithHeaderComponent` with left navigation; other pages are a single column.
- **LAY-6 SHOULD** Build spacing and sizes given in pixels by a mockup or issue (e.g., "40px", "319px wide") with Bootstrap utilities (`m*-`, `p*-`, `gap-*`, grid columns), rounded to the nearest step of the spacer scale (`1`–`5`: 4, 8, 16, 24, 48px). Similar elements on different pages (titles, boxes, button rows, section gaps) use the same spacing and sizes: match the existing instance rather than the mockup's value, unless the issue asks for the change, and then change every instance (CONS-3). Use exact pixel values in app SCSS only when the layout can't be achieved otherwise, with a `Design standard deviation:` comment giving the reason.

## Typography

- **TYPE-1 MUST** Fonts come from the component library: Source Sans 3, or Source Serif 4 where serif is needed. App SCSS does not set `font-family` (except for icon fonts).
- **TYPE-2 MUST** Type sizes come from the component library's heading scale, Bootstrap's `.small` and `fs-*` utilities, and the library's `.fs-14` / `.fs-15`. App SCSS does not declare `font-size`.
- **TYPE-3 MUST** No text is smaller than 0.875rem (14px).
- **TYPE-4 SHOULD** Use `fw-bold` for form labels and emphasis; avoid other weights and inline `font-weight` styles.

## Color

- **COLOR-1 SHOULD** Colors come from the Stanford palette (`--stanford-*` variables) or Bootstrap theme colors as remapped by the component library (`--bs-danger` etc.). Avoid new hex, rgb, or named colors in app SCSS.
- **COLOR-2 MUST** Contrast meets WCAG AA: 4.5:1 for normal text, 3:1 for large text (≥ 24px, or ≥ 18.66px bold), and 3:1 for icons, borders of controls, and focus indicators against adjacent colors.
- **COLOR-3** Object types have assigned colors (`$item-color`, `$collection-color`, `$admin-policy-color`, `$agreement-color`, `$virtual-object-color`, `$search-color`), applied through the `object-type-*` classes. **MUST** Text on or in an object-type color meets COLOR-2; check each color/text pair, since several of these colors reach only about 3:1 against white or black.

## Buttons

- **BTN-1 MUST** Button labels start with a verb and name the result (e.g., "Save", "Register items", "Deposit", "Start bulk action"). Don't use "Submit", "OK", or "Go".
- **BTN-2 SHOULD** A form or action area has one primary button: the action that completes it. Other actions are `outline-primary`. Explain more than one primary in review.
- **BTN-3 MUST** In a form footer, Cancel comes first, then other actions, then the primary action last. *Use* `Elements::FormFooterComponent`.
  - In a tabbed form's pane footer, Cancel and the tab navigation (Previous, Next) are on the left, and the save actions are on the right, with the primary action last.
- **BTN-4 SHOULD** Use `size: :sm` only inside tables, cards, boxes, and facets.
- **BTN-5** A button's variant may change with state (e.g., a step's action becoming primary once it can proceed).
- **BTN-6 MUST** A control for a feature not yet built (a placeholder) is a disabled control (the gem's `disabled:`, which removes the `href` and the tab stop), not a link to `#` or `/`.
- **BTN-7 MUST** Use a link for navigation and a button for actions. A control that changes data (delete, reset, purge) is a button, even when rendered as a link-styled button (`ButtonFormComponent`).
- **BTN-8 MUST** Destructive actions (discard, purge, delete, reset) ask for confirmation (`turbo_confirm` / the gem's `confirm:`). The message names the object and the consequence (e.g., "Discard the draft of <title>? This cannot be undone.").
- **BTN-9 MUST NOT** use modals. Use a separate page or an inline expanding section (`CollapsibleSectionComponent`) instead.

## Unavailable actions

- **AVAIL-1 MUST** Admin-only functions (e.g., the admin menu, Impersonate, Manage permissions) are hidden from users who are not admins.
- **AVAIL-2 MUST** Any other action the user lacks permission for is shown disabled, not hidden, so staff know it exists. This applies equally to buttons, menu items, and inline icon actions (e.g., an edit pencil). No explanation is required.
- **AVAIL-3 MUST** An action that can never apply to this kind of object (e.g., Manage files for an object type without files) is hidden.
- **AVAIL-4 MUST** An action unavailable because of the object's or form's current state (e.g., Deposit with Unsaved Changes, Republish before first publication) is disabled, with a visible reason as plain text right after it (e.g., "This object has never been published."), never only in a tooltip.
- **AVAIL-5 MUST** A disabled option within a field (a select option or radio button) is explained in the field's help text.
- **AVAIL-6** Controls disabled while a form submits or a file uploads need no reason, provided a spinner or progress indicator shows the work in progress.
- **AVAIL-7** Disabled controls use native `disabled` (the gem's `disabled:`), which removes them from the tab order; AVAIL-4's reason text, placed right after the control, keeps the reason in reading order for screen readers.

## Forms

- **FORM-1 MUST** A form is wrapped in `.b3-form` or a tab form (`.tab-form`) so field spacing and legend styles apply.
- **FORM-2 MUST** Every field has a visible label, bold (`label_classes: 'fw-bold'`). A visually hidden label (`label_hidden:` / `hidden_label:`) is allowed only where the purpose is clear from context (e.g., the search box, an input in a table row). A placeholder never stands in for a label.
- **FORM-3 MUST** Related radio buttons and checkboxes are grouped in a fieldset with a legend (`FieldsetComponent`, `RadioButtonGroupComponent`).
- **FORM-4 MUST** Required fields are marked with `mark_required` (visible `*` and "(required)" for screen readers).
- **FORM-5 MUST** Help text is attached to its field with `help_text:` so it is announced with the field. Information needed to fill in a field correctly (e.g., format, constraints) is visible help text, never only a tooltip.
- **FORM-6 MUST** Field errors are shown only through the gem's error components (field components, `InvalidFeedbackComponent`), which set `aria-invalid` and `aria-describedby`. Don't render errors as `<p class="text-danger">`.
- **FORM-7 MUST** Searchable selects use the Tom Select Stimulus controllers and follow the keyboard rule in `CODING_STANDARDS.md` (Forms).
- **FORM-8** Tooltips (when introduced) use the gem's `TooltipComponent` and give definitions or background only (see FORM-5).

### Choosing form elements

- **FORM-9 MUST** One choice from 2–4 options uses a radio group; from 5 or more options, or from a list that comes from data (e.g., APOs, licenses, workflows), a select. Exception: a form that sets the same choice for several targets in compact rows (e.g., release per discovery target) may use selects.
- **FORM-10 MUST** Choosing between alternative ways of providing something, where each option reveals its own follow-up fields (e.g., description from title, catalog ID, or spreadsheet), uses a radio group. Use a toggle (`ToggleComponent`) only to switch one section between two modes (e.g., without / with embargo).
- **FORM-11 MUST** A question that needs an explicit answer (e.g., "Perform OCR?") is a Yes / No radio group, ordered Yes then No. Use a single checkbox only for an option whose unchecked state is a safe default the user can ignore (e.g., "Close version").
- **FORM-12 MUST** A select with more than 15 options, or whose list grows with data (e.g., APOs, collections, workgroups), is searchable (Tom Select). It allows new values (`creatable-select`) only when values outside the list are legitimate (e.g., languages, MIME types).
- **FORM-13 MUST** Several choices from 10 or fewer options use a checkbox list in a fieldset; from more, a searchable multi-select. Don't use a native `<select multiple>`.
- **FORM-14 MUST** In a bulk action that can update more than one field, each field offers an explicit way to leave it unchanged, selected by default (e.g., a "Do not update ..." radio, or an unchecked "Change ..." checkbox that enables the field). A blank field never means "clear this".

## Tables

- **TABLE-1 MUST** Tables use the gem's table components (`TableComponent`, `RawTableComponent`).
- **TABLE-2 MUST** Every column has a header. A column of actions has a visually hidden header (e.g., "Actions"), not `label: ''`.
- **TABLE-3 MUST** A table has an accessible name: its caption (`label:`, hidden with `show_label: false` when a heading already precedes it) or a caption containing the heading.
- **TABLE-4 MUST** An empty table shows `empty_message:` worded "No <things>." (e.g., "No events."), not a hand-written paragraph.
- **TABLE-5 SHOULD** Column headers are words, not symbols (e.g., "Items", not "# of items").
- **TABLE-6 MUST** Column widths come from a CSS class, not inline styles (see LAY-3).
- **TABLE-7 MUST** A row that expands to show details has a `<button>` in a cell that toggles it, with `aria-expanded` and `aria-controls` (see A11Y-1). *Use* `Show::ToggleRowButtonComponent`.

## Links

- **LINK-1 MUST** Link text makes sense on its own. Repeated per-row links (e.g., "Log file") have visually hidden context (e.g., "Log file for <bulk action>"). No "click here", "here", "more", or "More »"; write "More <facet name>".
- **LINK-2 MUST** Open a new tab only for pages outside Argo B3 (e.g., PURL, Globus, downloads), using `link_to_new_tab` (or `new_tab_label` for a button with `target: '_blank'`), which announces the new tab.
- **LINK-3 SHOULD** Link to objects with `link_to_object` (object title as link text) and display druids without the `druid:` prefix.
- **LINK-4 MUST** Links have an `href`. *(linted)*

## Icons

- **ICON-1 MUST** Icons are Bootstrap Icons, rendered through the gem's or the app's icon helpers (`SdrViewComponents::Helpers::IconHelper`, `app/helpers/icon_helper.rb`). No raw `<i class="bi">`, CSS-injected icons, or one-off SVGs.
- **ICON-2 MUST** An icon beside text is decorative and has `aria-hidden` (`aria: { hidden: true }`).
- **ICON-3 MUST** An icon-only control has an accessible name from visually hidden text, using the gem's `IconButtonComponent`, `IconButtonLinkComponent`, or `IconButtonFormComponent`. A `title` attribute alone is not an accessible name.
- **ICON-4 SHOULD** The same action uses the same icon everywhere (e.g., `edit`, `delete`, `download`, `upload` helpers). An action icon (e.g., edit) never appears on something that can't be acted on.

## Feedback, loading, and empty states

- **FEED-1 MUST** Success and informational messages are disappearing toasts (`flash[:toast]`, or `ApplicationJob#broadcast_toast` from a job).
- **FEED-2 MUST** Errors that stop the user are a danger alert (`flash[:danger]`) or field errors (FORM-6). Warnings that don't stop the user are a warning alert (`flash[:warning]`). Don't use `flash[:success]` or other flash keys.
- **FEED-3 MUST** Inline alerts and banners use `AlertComponent`.
- **FEED-4 MUST** Loading content shows a spinner with text (`SpinnerComponent`, e.g., inside lazy turbo frames). Use `Elements::RosetteSpinnerComponent` for long waits and placeholder skeletons (`placeholder-glow`) for search results. No spinner without text, visible or visually hidden.
- **FEED-5 SHOULD** An empty list or section says so ("No <things>."), rather than rendering nothing.

## Copy

- **COPY-1 MUST** Use the terms in `GLOSSARY.md` (e.g., "APO", "Resource", "Draft", "Deposit", "Release Tag", "Tag"), not synonyms.
- **COPY-2 MUST** Use sentence case for headings, buttons, labels, legends, tabs, table headers, and navigation (e.g., "Select all", not "Select All").
- **COPY-3 MUST** Write acronyms and names in their standard form: APO, PURL, FOLIO, Solr, SearchWorks, EarthWorks, druid, Globus.
- **COPY-4 MUST** Labels, legends, headings, and buttons have no trailing colon or period.
- **COPY-5 MUST** Write "and", not "&". Don't use "»" or "←" in text, except the "←" of the back link (PAGE-4).
- **COPY-6 SHOULD** Address the user as "you", in plain language. Help text and messages are full sentences ending in a period.
- **COPY-7 MUST** Error messages say what went wrong and how to fix it.
- **COPY-8 MUST** Format dates with `format_datetime` (see `CODING_STANDARDS.md`), counts with `number_with_delimiter`, and file sizes with `number_to_human_size`.
