# Project Guidelines
Argo-B3 is a Rails application supporting the management of digital objects in the Stanford Digital Repository (SDR).

## Architecture

- Domain behavior usually lives in Cocina-backed Active Model form objects and presenters rather than conventional Active Record models.
- See the Voids gem (https://github.com/sul-dlss/voids) for the implementation of the form objects, which are similar to Active Record models.
- Structural metadata lives in Active Record `Content*` models (see GLOSSARY "Structural Metadata Terms"); read README "Structural metadata" before planning changes to it. Structural changes reach the cocina object via `CocinaObjectMutators::StructuralMutator` and `Sdr::Repository.update`, as in `StageFilesJob`.
- Authorization: `ApplicationPolicy` has `pre_check :allow_admins`, so admins pass every rule; policy rules decide only for non-admins.

## Conventions

- Match existing service, presenter, form object, and view component patterns before introducing new abstractions.
- Keep changes focused and avoid rewriting established search flow patterns unless the task requires it.
- Solr fields are referred to by constants which are defined in `app/services/search/fields.rb`.
- CSV import / export services live in a `<Kind>Csv` namespace (`::Import`, `::Export`, `::Validator`), e.g., `app/services/descriptive_csv/`, `app/services/structural_csv/`.
- Prefer full variable names instead of abbreviations (e.g., `full_variable_name` instead of `fvn` or `full_var_name`).
- `Current.effective_groups` is read only by the `Authentication` concern and Action Policy classes. Search and Solr services never read it; they receive a `Permissions::UserScope` as an explicit `user_scope:` argument, which controllers and jobs supply (`current_user_scope` in controllers).
- Changes and additions to the README should be for high level architectural notes and design choices only and should not include code level implementation details (which can be added inline in the code if warranted).

## Testing notes

- Run only the specs relevant to the change (`bin/rspec <files>`); for broad or full runs use `bin/parallel_rspec`. Set `COVERAGE=false` to drop SimpleCov output.
- Druids should match the pattern "^druid:[b-df-hjkmnp-tv-z]{2}[0-9]{3}[b-df-hjkmnp-tv-z]{2}[0-9]{4}$", e.g., "druid:bc123df4567".
- When creating multiple, unique druids for the same spec, vary at least the first 2 characters and the last 2 characters.
- For cocina factories, see https://github.com/sul-dlss/cocina-models/blob/main/lib/cocina/rspec/factories.rb
- Before writing or reviewing specs or code, read `CODING_STANDARDS.md` (judgement calls; linters enforce the mechanical rules).

## Checks

- Before reporting work done, run `bin/rake lint` (rubocop, erb_lint, herb, JS and SCSS linters); fix offenses before committing.

## References
For gems, read the source at the indicated path rather than guessing interfaces. If this local source isn't available, read from Github.

- See `README.md` for setup, linting, testing, models / forms, structural metadata, bulk actions, and discovery / search / faceting details.
- Cocina Models (Repository: https://github.com/sul-dlss/cocina-models, Namespace: `Cocina::Models`) - Ruby implementation of the SDR data model for DROs (digital repository objects), Collections, and Admin Policies. It can usually be found locally for reading at `../cocina-models`.
- DOR Services Client (Repository: https://github.com/sul-dlss/dor-services-client, Namespace: `Dor::Services::Client`) - Client for interacting with DOR Services App (DSA), the backend of SDR. It can usually be found locally for reading at `../dor-services-client`.
- Technical Metadata Service (Repository: https://github.com/sul-dlss/technical-metadata-service) - Provides technical metadata (e.g., mimetype, dimensions) for deposited files. The API, including response schemas, is in `openapi.yml`; it can usually be found locally at `../technical-metadata-service`.
- SDR View Components (Repository: https://github.com/sul-dlss/sdr_view_components, Namespace: `SdrViewComponents`) - A rails gem to provide reusable view components for SDR applications. It can usually be found locally for reading at `../sdr_view_components`. When working with the UI, prefer reusing components from SDR View Components.
