# Coding Standards

Judgement calls checked during review. Mechanical rules are enforced by RuboCop, erb_lint, herb, and the JS / SCSS linters (`bin/rake lint`), so they are not repeated here.

## Forms

- Searchable select widgets (tom-select, single or multi) commit the highlighted option, or create a new value, only on Enter or click. Tab always moves focus to the next field without selecting or creating anything, as with a native `<select>`, so keyboard users can move through a form without accidentally changing values. Don't enable tom-select's `selectOnTab`.
- An `Edit::*` component that renders form fields says in its class comment which concerns the form's object must include or, where no concern provides them, which attributes it must provide (e.g., `Edit::CatalogRecordIdComponent`). Components that only render other edit components are exempt. Update the comment when the fields a component renders change.
- In a form object, put each attribute's normalization and validations directly after its `attribute` declaration.

## Turbo

- When a form or button changes the page it was submitted from (e.g., adding or deleting a row), update the page with a morph, not turbo streams. The page sets the `turbo-refresh-method` `morph` and `turbo-refresh-scroll` `preserve` meta tags. On success, redirect back to the page (`status: :see_other`, toast in `flash[:toast]`). On failure, render the page with `status: :unprocessable_content`. Turbo morphs both, so you don't need `*.turbo_stream.erb` views or partials pulled out for replacement. On a page that refreshes itself periodically, use `ToastAndRefreshConcern` so the background refresh can't consume the flash.
- Use turbo streams only when a morph of the submitting page can't do the job: broadcasts to other browsers (`turbo_stream_from`), appending toasts, or updating part of a page that is too costly to re-render.
- Widgets that morphing would break are made morph-safe in their Stimulus controller (e.g., Tom Select controllers use `MorphableTomSelect`). Don't work around them with turbo streams or by skipping the morph.
- Give a morphed form with radio buttons a stable `id` (e.g., `form_with ..., id: 'object-permission-form'`). Without one, the morph builds a new form and moves the radios into it one at a time, and moving a still-checked radio unchecks the one already reset, leaving none checked.

## Views

- Don't put `<%= %>` inside an HTML attribute. When an element's attributes take Ruby values, build the element with a tag helper (`tag.div`, `tag.span`, `link_to`, etc.) and pass the attributes as arguments, using a `data:` hash for `data-*` attributes (e.g., the container in `objects/show.html.erb`).

## Specs

### What to test
- Unless specifically asked, do not write tests for memoization, caching, getters, or default values. These restate the implementation and break on refactors without catching regressions. Security-relevant behavior is not a "default" and should be tested (e.g., an attribute excluded from `permitted_params`, a field that cannot be changed).
- Every `describe` / `context` / `it` description is backed by an assertion. For example, a "with errors" context asserts the error message (e.g., `have_invalid_feedback`), not just the absence of success.
- Every change to a component's rendered output adds or updates its component spec (`spec/components/...`), even when a system spec also covers it.

### Expected values
- Expected values are independent of the implementation. Do not compute them with the code under test or the helpers, constants, or expressions it uses (e.g., `DruidSupport.bare_druid_from`, `Form.permitted_params`, `File.size(filepath_on_disk)`); use literals instead (e.g., `'bc123df4567'`, `[:tag]`, `52`).
- Configuration is an input, not the code under test: reference `Settings.*` (e.g., `"#{Settings.purl.url}/preview"`) rather than copying values from `config/settings.yml` into the spec, so specs survive config changes.

### Stubbing
- Do not stub the class under test (e.g., `allow(described_class).to receive(:new)`). Stub at external boundaries (Solr, `Dor::Services::Client`) and assert on what the code sends or returns.
- Test arguments with `with` in the `expect(...).to have_received`, not in the `allow`; do not test them in both.

### Layout
- Place `let` statements before `before` blocks.
- CSS matchers do not test padding or margins (e.g., `ps-3`, `mt-1`).

## Ruby / Rails

- Guard against what can actually happen. Leave out checks, validations, and 404s for input that the app's own links, routes, and widgets can't produce: e.g., a druid param from an app-built link (use it as-is), an object type that a "Manage" button never links to, or a radio value outside its options. An unknown record already 404s through `Sdr::Repository::NotFoundResponse`. Normalize and validate what a user types (e.g., `ObjectsController#show`, the go-to-druid form).
- Controllers stay thin: they authorize, build the form, save, and redirect or render. Domain steps (e.g., opening a version, updating the version description, starting accessioning) belong in the form's `save!`, `CocinaModels::Base#save!`, `Sdr::Repository`, or a service class. When `Metrics/AbcSize` fires on a controller action, move logic down a layer rather than extracting private controller helpers.
- Authorize inline at the top of each action (`authorize! @bulk_action`), not in a `before_action`, so every endpoint shows its own rule and record. A `before_action` may load the record (e.g., `set_bulk_action`); the action authorizes it. Keep that order even though an unauthorized user then gets a 404 for a missing record. The exception is a controller whose actions are defined elsewhere, such as a base class (`BulkActions::ImportReadUnrestrictedWorkgroupsController`) or a mounted engine (`MissionControlAuthorizationController`).
- In an `ActiveSupport::Concern`, define instance methods in the module body, not inside `included do`.
- Every `rescue StandardError` in a job logs the error (`Rails.logger.error(e.full_message)`) and notifies Honeybadger (`Honeybadger.notify(e)`), as in `BulkActions::BaseRegisterJob`.
