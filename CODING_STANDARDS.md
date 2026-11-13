# Coding Standards

Judgement calls checked during review. Mechanical rules are enforced by RuboCop, erb_lint, herb, and the JS / SCSS linters (`bin/rake lint`), so they are not repeated here. When reviewing, check each rule against every changed file it applies to.

For changes to views, components, SCSS, UI JavaScript, or user-facing copy, also apply `DESIGN_STANDARDS.md`.

## Forms

- Searchable select widgets (tom-select, single or multi) commit the highlighted option, or create a new value, only on Enter or click. Tab always moves focus to the next field without selecting or creating anything, as with a native `<select>`, so keyboard users can move through a form without accidentally changing values. Don't enable tom-select's `selectOnTab`.
- An `Edit::*` component that renders form fields says in its class comment which concerns the form's object must include or, where no concern provides them, which attributes it must provide (e.g., `Edit::CatalogRecordIdComponent`). Components that only render other edit components are exempt. Update the comment when the fields a component renders change.
- In a form object, put each attribute's normalization and validations directly after its `attribute` declaration.

## Turbo

- When a form or button changes the page it was submitted from (e.g., adding or deleting a row), update the page with a morph, not turbo streams. The page sets the `turbo-refresh-method` `morph` and `turbo-refresh-scroll` `preserve` meta tags. On success, redirect back to the page (`status: :see_other`, toast in `flash[:toast]`). On failure, render the page with `status: :unprocessable_content`. Turbo morphs both, so you don't need `*.turbo_stream.erb` views or partials pulled out for replacement. On a page that refreshes itself periodically, use `ToastAndRefreshConcern` so the background refresh can't consume the flash.
- Use turbo streams only when a morph of the submitting page can't do the job: broadcasts to other browsers (`turbo_stream_from`), appending toasts, or updating part of a page that is too costly to re-render.
- Widgets that morphing would break are made morph-safe in their Stimulus controller (e.g., Tom Select controllers use `MorphableTomSelect`).
- Give a morphed form with radio buttons a stable `id` (e.g., `form_with ..., id: 'object-permission-form'`). Without one, the morph builds a new form and moves the radios into it one at a time, and moving a still-checked radio unchecks the one already reset, leaving none checked.

## Views

- Render dates and times with `format_datetime` (`ApplicationHelper`, `helpers.format_datetime` in components) and a format from `time.formats` in `config/locales/en.yml` (e.g., `format: :date_only`), not `strftime` or `to_fs`. It converts to Pacific time first, so every page shows the same zone and layout. Add a new format to `en.yml` if none fits.
  - The `PT` label is used year-round, though the time observes daylight saving. Exceptions: CSV report values, which arrive preformatted from Solr, and machine-readable values (Solr queries, repository API values, HTTP headers), which use their protocol's format.
- Notify the user of an error with a danger alert (`flash[:danger]`), of a warning that doesn't stop them or a refused action (e.g., the object is not editable, its content is busy, or the page is stale) with a warning alert (`flash[:warning]`), and of informational messages (status updates, success) with a disappearing toast (`flash[:toast]`, or `ApplicationJob#broadcast_toast` from a job).
- Components and presenters render the data they are given. They don't query Active Record, Solr, or other services; the controller (or the form or service it calls) loads the records and passes them in. Chaining scopes, `order`, `count`, or `pluck` onto a passed relation is a query too.

## Naming and structure

- Use full variable names (e.g., `full_variable_name`, not `fvn` or `full_var_name`).
- Refer to Solr fields by the constants in `app/services/search/fields.rb`.
- Put CSV import / export services in a `<Kind>Csv` namespace (`::Import`, `::Export`, `::Validator`), e.g., `app/services/descriptive_csv/`, `app/services/structural_csv/`.

## Specs

### What to test
- Test behavior a refactor would preserve. Unless asked, leave out tests of memoization, caching, getters, and default values: they restate the implementation and break on refactors without catching regressions. Security-relevant behavior is not a "default" and should be tested (e.g., an attribute excluded from `permitted_params`, a field that cannot be changed).
- Prefer request specs, which are much faster than system specs. Reserve system specs for behavior that requires a browser, such as JavaScript (Stimulus controllers, lazy Turbo frames, auto-refresh) or file downloads. If a system spec does not need JavaScript (e.g., a multi-page flow), mark it `:rack_test`.
- Every `describe` / `context` / `it` description is backed by an assertion. For example, a "with errors" context asserts the error message (e.g., `have_invalid_feedback`), not just the absence of success.
- Every change to a component's rendered output adds or updates its component spec (`spec/components/...`), even when a system spec also covers it, unless the change is presentation-only (see below).
- Assert on content and behavior, not presentation. Presentation covers spacing, sizing, grid, flex, alignment, and visual-variant classes (e.g., `mt-1`, `gap-4`, `col-lg-3`, `text-end`, `h5`), rendered sizes or positions, decorative icons (e.g., arrows), and static markers such as required-field asterisks. A presentation-only change needs no new spec; show it in the PR screencast instead. Content order in the DOM (e.g., which button comes first) is behavior and may be tested.
- When removing markup or an attribute, delete or update the specs that covered it rather than adding one that asserts its absence.

### Expected values
- Expected values are independent of the implementation. Do not compute them with the code under test or the helpers, constants, or expressions it uses (e.g., `DruidSupport.bare_druid_from`, `Form.permitted_params`, `File.size(filepath_on_disk)`); use literals instead (e.g., `'bc123df4567'`, `[:tag]`, `52`).
- Configuration is an input, not the code under test: reference `Settings.*` (e.g., `"#{Settings.purl.url}/preview"`) rather than copying values from `config/settings.yml` into the spec, so specs survive config changes.

### Test data
- Druids match `^druid:[b-df-hjkmnp-tv-z]{2}[0-9]{3}[b-df-hjkmnp-tv-z]{2}[0-9]{4}$`, e.g., `druid:bc123df4567`. When a spec needs several, vary at least the first 2 and the last 2 characters.
- Build cocina objects with the cocina-models factories (`../cocina-models/lib/cocina/rspec/factories.rb`).

### Stubbing
- Stub at external boundaries (Solr, `Dor::Services::Client`), not the class under test (e.g., `allow(described_class).to receive(:new)`), and assert on what the code sends or returns.
- Test arguments with `with` in the `expect(...).to have_received`, not in the `allow`; do not test them in both.

### Spec file layout
- Place `let` statements before `before` blocks.

## Ruby / Rails

- Guard against what can actually happen. Leave out checks, validations, and 404s for input that the app's own links, routes, and widgets can't produce: e.g., a druid param from an app-built link (use it as-is), an object type that a "Manage" button never links to, or a radio value outside its options. An unknown record already 404s through `Sdr::Repository::NotFoundResponse`. Normalize and validate what a user types (e.g., `ObjectsController#show`, the go-to-druid form).
- Controllers stay thin: they authorize, build the form, save, and redirect or render. Domain steps (e.g., opening a version, updating the version description, starting accessioning) belong in the form's `save!`, `CocinaModels::Base#save!`, `Sdr::Repository`, or a service class. When `Metrics/AbcSize` fires on a controller action, move logic down a layer rather than extracting private controller helpers.
- Authorize inline at the top of each action (`authorize! @bulk_action`), not in a `before_action`, so every endpoint shows its own rule and record. A `before_action` may load the record (e.g., `set_bulk_action`); the action authorizes it. Keep that order even though an unauthorized user then gets a 404 for a missing record. The exception is a controller whose actions are defined elsewhere, such as a mounted engine (`MissionControlAuthorizationController`).
- For bulk actions, each job item checks the permission its action needs before acting on the object: `check_update_ability?` before changing it, `check_read_ability?` before exporting it, or other permissions as appropriate. Spec the refusal with a user who lacks the permission, not by stubbing the check.
