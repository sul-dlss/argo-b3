# Coding Standards

Judgement calls checked during review. Mechanical rules are enforced by RuboCop, erb_lint, herb, and the JS / SCSS linters (`bin/rake lint`), so they are not repeated here.

## Forms

- Searchable select widgets (tom-select, single or multi) commit the highlighted option, or create a new value, only on Enter or click. Tab always moves focus to the next field without selecting or creating anything, as with a native `<select>`, so keyboard users can move through a form without accidentally changing values. Don't enable tom-select's `selectOnTab`.

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

- Controllers stay thin: they authorize, build the form, save, and redirect or render. Domain steps (e.g., opening a version, updating the version description, starting accessioning) belong in the form's `save!`, `CocinaModels::Base#save!`, `Sdr::Repository`, or a service class. When `Metrics/AbcSize` fires on a controller action, move logic down a layer rather than extracting private controller helpers.
- In an `ActiveSupport::Concern`, define instance methods in the module body, not inside `included do`.
- Every `rescue StandardError` in a job logs the error (`Rails.logger.error(e.full_message)`) and notifies Honeybadger (`Honeybadger.notify(e)`), as in `BulkActions::BaseRegisterJob`.
- Read form params with the form's param key (`Form.model_name.param_key`); Voids drops the `Form` suffix (`EventsFilterForm` submits as `events_filter`).
