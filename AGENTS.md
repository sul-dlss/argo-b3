# Project Guidelines

## Architecture

- Domain behavior usually lives in Cocina-backed wrappers and presenters rather than conventional Active Record models.

## Conventions

- Match existing service, presenter, form object, and view component patterns before introducing new abstractions.
- Keep changes focused and avoid rewriting established search flow patterns unless the task requires it.
- Solr fields are referred to by constants which are defined in `app/services/search/fields.rb`.

## Testing notes

- Druids should match the pattern "^druid:[b-df-hjkmnp-tv-z]{2}[0-9]{3}[b-df-hjkmnp-tv-z]{2}[0-9]{4}$", e.g., "druid:bc123df4567".
- When creating multiple, unique druids for the same spec, vary at least the first 2 characters and the last 2 characters.
- For cocina factories, see https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/rspec/factories.rb
- Prefer instance_doubles instead of doubles.
- Unless specifically told to, do not write tests for:
  - Memoization
  - Caching
- For mocking, place allow statements in a before block and expect statements after the action is performed. Prefer testing argument (with) in expect; do not test in both allow and expect.
- Place let statements before before blocks.
- When writing CSS matchers, do not test padding or margins (e.g., ps-3, mt-1).

## References

- See `README.md` for setup, linting, testing, and discovery details.
