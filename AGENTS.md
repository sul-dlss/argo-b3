# Project Guidelines
Argo-B3 is a Rails application supporting the management of digital objects in the Stanford Digital Repository (SDR).

## Architecture

- Domain behavior usually lives in Cocina-backed Active Model form objects and presenters (built on Voids; see References) rather than conventional Active Record models.
- Structural metadata lives in Active Record `Content*` models (see GLOSSARY "Structural Metadata Terms"); read README "Structural metadata" before planning changes to it. Structural changes reach the cocina object via `CocinaObjectMutators::StructuralMutator` and `Sdr::Repository.update`, as in `StageFilesJob`.
- The database schema is `db/structure.sql` (there is no `schema.rb`); local services (Postgres, Redis, Solr, DSA, SURI) are in `compose.yaml`.
- Authorization: `ApplicationPolicy` has `pre_check :allow_admins`, so admins pass every rule; policy rules decide only for non-admins.
- `Current.effective_groups` is read only by the `Authentication` concern and Action Policy classes. Search and Solr services never read it; they receive a `Permissions::UserScope` as an explicit `user_scope:` argument, which controllers and jobs supply (`current_user_scope` in controllers).

## Conventions

- Before writing or reviewing code or specs, read `CODING_STANDARDS.md`: the judgement calls linters don't enforce.
- Before changing models, forms, presenters, or search, or adding a facet, search result field, sort option, or bulk action, read the matching `README.md` section; the "Adding ..." sections are step-by-step recipes.
- Changes and additions to the README should be for high level architectural notes and design choices only and should not include code level implementation details (which can be added inline in the code if warranted).

## Testing notes

- In a new git worktree, run `bin/setup-worktree` before specs or linters (it copies gitignored local files, installs JS dependencies, and builds CSS).
- Run only the specs relevant to the change (`bin/rspec <files>`); for broad or full runs use `bin/parallel_rspec`. Set `COVERAGE=false` to drop SimpleCov output.

## Integration tests

End-to-end Argo-B3 flows are covered by `spec/features/accessioning/argo_b3_*_spec.rb` in sul-dlss/infrastructure-integration-test (usually at `../infrastructure-integration-test`); read them to see which flows they exercise. When writing or reviewing a change to one of those flows, remind the developer to run the integration tests before merging.

## Checks

- Before reporting work done, run `bin/rake lint` (rubocop, erb_lint, herb, JS and SCSS linters, i18n-tasks); fix offenses before committing.

## References
For gems, read the source at the indicated path rather than guessing interfaces. If this local source isn't available, read from Github.

- Voids (Repository: https://github.com/sul-dlss/voids) - Active Record-like base for the form objects and models. It can usually be found locally for reading at `../voids`.
- Cocina Models (Repository: https://github.com/sul-dlss/cocina-models, Namespace: `Cocina::Models`) - Ruby implementation of the SDR data model for DROs (digital repository objects), Collections, and Admin Policies. It can usually be found locally for reading at `../cocina-models`.
- DOR Services Client (Repository: https://github.com/sul-dlss/dor-services-client, Namespace: `Dor::Services::Client`) - Client for interacting with DOR Services App (DSA), the backend of SDR. It can usually be found locally for reading at `../dor-services-client`.
- DOR Services App (DSA) (Repository: https://github.com/sul-dlss/dor-services-app) - The SDR backend: object persistence, versioning, and workflow definitions (`config/workflows/*WF.xml`, e.g., `goobiWF.xml`). It can usually be found locally at `../dor-services-app`.
- Robots that run workflow steps: `../common-accessioning` (accession, assembly, OCR, speech-to-text) and `../gis-robot-suite` (GIS assembly and derivatives), with robots under `lib/robots/dor_repo/`.
- Preservation Client (Repository: https://github.com/sul-dlss/preservation-client, Namespace: `Preservation::Client`) - Client for preserved files and versions. It can usually be found locally at `../preservation-client`.
- Pre-Assembly (Repository: https://github.com/sul-dlss/pre-assembly) - Stages and accessions batches of objects from files on a mount. It can usually be found locally at `../pre-assembly`.
- Deployed settings are in `../shared_configs`, one branch per app and environment (e.g., `origin/argo-b3`, `origin/sul-preassembly-prod`, `origin/dor-services-app-prod`); read them with `git -C ../shared_configs show origin/<branch>:<path>`.
- Technical Metadata Service (Repository: https://github.com/sul-dlss/technical-metadata-service) - Provides technical metadata (e.g., mimetype, dimensions) for deposited files. The API, including response schemas, is in `openapi.yml`; it can usually be found locally at `../technical-metadata-service`.
- SDR View Components (Repository: https://github.com/sul-dlss/sdr_view_components, Namespace: `SdrViewComponents`) - A rails gem to provide reusable view components for SDR applications. It can usually be found locally for reading at `../sdr_view_components`. When working with the UI, prefer reusing components from SDR View Components.
