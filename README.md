[![CircleCI](https://dl.circleci.com/status-badge/img/gh/sul-dlss/argo-b3/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/sul-dlss/argo-b3/tree/main
)
[![Test Coverage](https://codecov.io/github/sul-dlss/argo-b3/graph/badge.svg?token=9Y9EL3VG6I)](https://codecov.io/github/sul-dlss/argo-b3)

# README

## Development

Be sure to have installed at least the version of Ruby noted in the [Dockerfile](https://github.com/sul-dlss/argo-b3/blob/main/Dockerfile) and the version of node indicated in [`.node-version`](https://github.com/sul-dlss/argo-b3/blob/main/.node-version).

### Running the application

```
docker compose up -d
bin/setup
```

Note that `bin/setup` will create the database, run yarn, and perform other setup tasks.

The roles, email address, and name of the test user can be provided in environment variables. Defaults are set in `bin/dev`.

### Development script for running locally connecting to remote services

For running code in localhost pointing to real data on a server environment but talking to your local database, `bin/dev-server` will facilitate the setup described above.

1. Ensure you are on VPN, have a valid kerberos ticket, and docker desktop client is running.
2. Running `bin/dev-server` sets up the jumphost (if needed), opens a solr tunnel in the background, ensures required docker containers are up, configures the environment variables for connection to qa/stage/prod services, and starts the localhost server. The script can be passed a parameter of "stage", "qa" or "prod" (e.g. `bin/dev-server stage`). It defaults to "qa" if no environment is passed. Running against prod also requires `ALLOW_PROD=true`.
3. Service settings (e.g., URLs) come from `config/deploy.<env>.yml` and the secrets for them (e.g., DSA, PresCat, and techmd tokens and the Folio password) come from Vault, so the `vault` CLI is required; the script launches `vault login -method oidc` if needed. Any `SETTINGS__*` variable already exported in your shell takes precedence. RabbitMQ is configured for the environment but event publishing stays disabled unless you run with `SETTINGS__RABBITMQ__ENABLED=true`.

You can also start a local rails console that connects to the remote services but local database in the same way by appending `console` to the script, e.g. `bin/dev-server stage console` or just `bin/dev-server console` for the default QA environment).


### Bootstrapping an agreement, APO, and collection

```
bin/rake development:bootstrap_agreement
bin/rake development:bootstrap_apo
bin/rake "development:bootstrap_collection[<APO DRUID>]"
```

### Completing assembly and accessioning

Without robots running locally, deposited objects get stuck in assemblyWF / accessionWF. To mark the incomplete steps as completed (closing the version if necessary):

```
bin/rake "development:complete_workflows[<DRUID>]"
```

Note that this only updates workflow step statuses; the work of the robots (e.g., shelving, publishing, preservation) is not performed.

### Linters

To run all configured linters, run `bin/rake lint`.

To run linters individually, run which ones you need:

* Ruby code: `bin/rubocop` (add `-a` flag to autocorrect violations)
* ERB templates: `bin/erb_lint --lint-all --format compact` (add `-a` flag to autocorrect violations)
* ERB templates: `yarn run herb-lint app` (add `--fix` flag to autocorrect violations; project rules are in `.herb/rules`)
* JavaScript code: `yarn run lint` (add `--fix` flag to autocorrect violations)
* SCSS stylesheets: `yarn run stylelint` (add `--fix` flag to autocorrect violations)

### Background Jobs UI

A dashboard for SolidQueue background jobs is available at http://localhost:3000/jobs

### Lookbook for SDR View Components

In development, available at http://localhost:3000/lookbook

## Deployment with Kamal
* See `--hosts` to run only on specific hosts.
* See `--roles` to run only for specific roles (e.g., `web` or `job`)

Note:
* Honeybadger deploy notifications are performed in `.kamal/hooks/post-deploy`.
* Kamal deploy secrets are resolved from environment variables via `.kamal/secrets-common`.
  * In CI, Jenkins injects those variables from Vault and runs `bin/kamal` directly.
  * For local deploys, `bin/kamal-otk` invokes Kamal via `bin/with-deploy-env`, which loads any missing deploy secrets from Vault.
* The Dockerfile configures the lyberadmin (50:503) user to match the host server.
* `/workspace/bulk` and `/var/log/argo` are shared with the containers.
* The docker image is built on the stage server (AMD64) for all environments to avoid emulation on the developer Mac. Sharing one builder keeps its layer cache warm across environments.

### Adding a secret

Secrets are stored in Vault and provided to the containers as environment variables. Settings secrets are named `SETTINGS__<SECTION>__<KEY>` (e.g., `SETTINGS__TECH_MD_SERVICE__TOKEN` overrides `Settings.tech_md_service.token`).

To add a secret:

1. Add the secret to Vault (as the `content` field), e.g., `vault kv put puppet/application/argo-b3/qa/my-secret content=...`.
   * For a secret that varies by environment, add one per destination at `puppet/application/argo-b3/<qa|stage|prod>/<secret-name>`.
   * For a secret shared by all environments, add it at `puppet/application/argo-b3/<secret-name>`.
2. Add the environment variable to `env.secret` in `config/deploy.yml`.
3. Add `NAME=${NAME}` to `.kamal/secrets-common`.
4. Add its Vault path to `vault_secret_path` in `bin/with-deploy-env` (for local deploys and, for `SETTINGS__*` secrets, `bin/dev-server`).
5. Add the environment variable to `secrets` in `Jenkinsfile` (for continuous deployment to stage). Use the stage path, omitting the `puppet/` prefix (e.g., `application/argo-b3/stage/<secret-name>`).

### Deploy

To build and deploy the local, committed code:

```
bin/kamal-otk qa deploy
```

For local deploys, `bin/kamal-otk` loads deploy secrets from Vault (via `bin/with-deploy-env`) only when they are missing from the current environment, then runs Kamal.

#### Deploying faster when deploying to all environments

To avoid rebuilding images:

```
bin/kamal-otk qa deploy
bin/kamal-otk stage deploy --skip-push
bin/kamal-otk prod deploy --skip-push
```

#### Rollback
```
bin/kamal-otk qa app containers -q
bin/kamal-otk qa rollback e5d9d7c2b898289dfbc5f7f1334140d984eedae4
```

Use `app containers -q` to get the image ids of the containers to roll back to.

#### Stop / start
```
bin/kamal-otk qa app stop
bin/kamal-otk qa app start
```

#### Maintenance
```
bin/kamal-otk qa app maintenance --message "Wait for it..."
bin/kamal-otk qa app live
```

#### Console

To run a rails console on a deployed environment:

```
bin/kamal-otk prod console
```

To run a shell inside the deployed app container:

```
bin/kamal-otk prod shell
```

### Monitoring

#### App status
```
bin/kamal-otk qa details
```

#### Container status
```
bin/kamal-otk qa app containers
```

#### Deployed version
```
bin/kamal-otk qa app version
```

#### Logs
```
bin/kamal-otk qa app logs -f
```

* For log filtering options, see `bin/kamal-otk qa app logs --help`.
* For log rotation, see `logging` in `deploy.yml`.
* The application also logs to `/var/log`.

### Interacting
See https://kamal-deploy.org/docs/commands/running-commands-on-servers/

#### With the server
```
bin/kamal-otk qa ssh
bin/kamal-otk qa server exec "docker -v"
```

#### With a container
```
bin/kamal-otk qa console
bin/kamal-otk qa db
bin/kamal-otk qa shell
```

## Testing

### Solr
To reset Solr before and after a test, mark the test as `:solr`. For example:
```
RSpec.describe 'My test', :solr do
```

Solr document test fixtures can be created with the Solr factories. For example:
```
let!(:solr_doc) { create(:solr_item) }
```

### Running tests in parallel
[parallel_tests](https://github.com/grosser/parallel_tests) will significantly speed up running tests locally.

```
bin/parallel_rspec
```

Before running the first time: `bin/rake parallel:prepare parallel:seed`
After a migration: `bin/rake parallel:migrate`

## Models
`CocinaModels::*` are Active Model wrappers around `Cocina::Models::*` objects. They are intended to provide a mutable, simplified interface to the underlying cocina objects.

Note: By convention, `CocinaModels::*` instances are referred to as "cocina models" and instances of `Cocina::Models::*` are referred to as "cocina objects".

Translation between cocina objects and cocina models is handled in both directions by separate service classes:
* **Mappers** (`CocinaModelMappers::*`) map a cocina object to the hash of attributes used to build a cocina model. This happens when a cocina model is built from a cocina object (e.g., one retrieved from DSA).
* **Mutators** (`CocinaObjectMutators::*`) produce a new cocina object by merging a cocina model's attributes into a cocina object. When saving, the mutator starts from the cocina object the model was built from, so any parts of the cocina object that the model does not represent are retained unchanged. When creating, the mutator starts from a minimal request cocina object.

Since the cocina model only represents a subset of the cocina object, the mappers and mutators must be kept in sync: an attribute that is mapped from a cocina object should be written back by the corresponding mutator.

## Model presenters
`CocinaModels::*Presenter` are `SimpleDelegator` wrappers around cocina models primarily for use in views. Model presenters are immutable and should enhance cocina models with additional display fields and convenience methods.

Note: Where possible, `CocinaDisplay` should be used for extracting description from cocina objects.

## Forms
Form objects (`app/forms`) back the application's HTML forms. They are Active Model objects built on Voids, so they support attributes, normalization, validation, and nested associations, and they declare the params that controllers should permit (via `PermittedParamsConcern`).

There are two kinds of forms:
* Forms that create or edit a cocina object (e.g., `NewItemForm`, `ContentsItemForm`) subclass the relevant cocina model (e.g., `CocinaModels::Dro`) rather than `ApplicationForm`. This allows them to reuse the cocina model's attributes, mapping, mutation, and persistence (`create!` / `save!`), while adding form-only concerns: attributes that exist only to drive the UI (e.g., choosing between providing or generating a source ID), conditional validations, and callbacks that derive cocina model attributes from those form-only attributes before validation. Different editing contexts for the same type of object get their own form (and endpoint) so that each only permits and validates the attributes it edits.
  * Forms that edit a saved object include `EditCocinaObjectFormConcern`, which owns the version flow: it builds the form for the edit page or from a submission, separates form-only attributes from changes to save, and on `save!` opens a version (or updates the open version's description) before saving. Forms supply only what varies: when a closed version must be opened, and how saving updates the object's mutable Content. Their controllers include `EditCocinaObjectConcern`, which loads the object and provides the not-editable and stale (lock changed since the edit page loaded) guards, so a controller supplies only its form, i18n scope (by controller name), and edit view.
* All other forms subclass `ApplicationForm` (e.g., `TicketTagForm`, `ReleaseTagsForm`, search forms, bulk action forms). These are not backed by a cocina object, though some still perform an action (e.g., `ReleaseTagsForm#create!`).

## Structural metadata
Unlike other parts of a cocina object, structural metadata (file sets and files) is not wrapped by a cocina model. Instead, it is held in the DB as Active Record models, since it can be large and is edited incrementally (e.g., uploading files, discovering files, reordering file sets) over many requests:
* `Content` - the structure of a DRO for a particular version of the cocina object, identified by the druid and the cocina object's lock.
* `ContentFileSet` - a cocina file set, ordered within the `Content`.
* `ContentFile` - a cocina file as it occurs within a particular file set, ordered within the `ContentFileSet` and holding the file-level attributes (e.g., access, preserve / shelve / publish).
* `ContentFileBinary` - the physical file, identified by its filepath. It holds the properties of the physical file (e.g., size, digests, mime type, and image dimensions), so they are retained when the structure is rebuilt. The mime type is determined by Marcel. Since the same file may be referenced by more than one file set, a binary may have multiple `ContentFile`s. A binary that is not referenced by any `ContentFile` ("unassociated") is not part of the structure (e.g., a file that has been uploaded but not yet placed in a file set).

A `Content` is either **immutable**, in which case it exactly reflects the structural metadata of the cocina object version identified by its lock (e.g., for display and structural CSV export), or **mutable**, in which case it is being edited and may have deviated from the cocina object.

Mapping to and from cocina structural metadata:
* `Contents::Builder` builds a `Content` from a cocina object's structural metadata, deduplicating files with the same filepath into a single `ContentFileBinary`.
* `CocinaObjectMutators::StructuralMutator` rebuilds a cocina object's structural metadata from a `Content`. Before doing so, it validates that every file set, file, and binary is ready for deposit (the `:deposit` validation context); earlier in the editing flow these records are allowed to be incomplete.

Each `ContentFileBinary` records where its physical file is located (`file_location`). Files move from where they were added (`attached` for files uploaded via the browser and stored with Active Storage, `mount` for files on a mounted filesystem, and `globus` for files on the Globus filesystem) to `stage`, and binaries built from an existing cocina object are `deposited` (already accessioned and stored in preservation / stacks).

Files are added to a mutable `Content` as unassociated binaries, either by upload or by **discovery** (`DiscoverFilesJob` recursively lists the files in a directory on a mount). For Globus, Argo-B3 creates a directory per user and object on the Globus endpoint and grants the user write access; since the Globus filesystem is also mounted, discovery and staging then work as for any other mount, but the binaries are recorded as `globus`. Ignored files (e.g., `.DS_Store`) never become binaries. The `Contents::Populators` then structure the unassociated binaries into file sets and files, using a strategy appropriate to the content type (e.g., for a book, files that share a filename apart from the extension, such as the image and OCR for a page, are grouped into one file set; for media, audio and video files that share a filename apart from the extension are grouped into one file set, and files named with SMPL's File Flags (e.g., `_pm`, `_sl`) are grouped by recording, with the access copy published). `Contents::PopulatorSelector` picks the populator and falls back to one file set per file when the content type's populator cannot handle the files.

A structural CSV import (`StructuralCsv::Import`) replaces a mutable `Content`'s file sets and files; it cannot add files, and any binary that no row references is deleted. Uploading a structural CSV from manage files rejects such deletions unless the user explicitly allows files to be deleted.

**Content type validation** (`Contents::Validator`) checks whether a `Content`'s structure suits the item's content type, so that a deposited item won't break the embed viewer (e.g., for a book, each `page` resource may publish only one JP2 plus its OCR files). Each content type has its own validator (content types without one get only the checks shared by all content types), and a result has **errors**, which block deposit, and **warnings**, which don't (e.g., no resource has an image the viewer can display). Mirroring DSA, hierarchical filepaths are an error, even for a dark object, for every content type except file and geo. For an object that is already dark, a file that is not dark, or is published or shelved, is an error for every content type; saving an object that is being made dark overwrites its files' access instead (see Overwrite File Access in the glossary).

**Staging** (`StageFilesJob`) saves a mutable `Content` to the cocina object. It mints identifiers for new file sets and files, computes digests / size / mime type, copies the files to the staging location, and updates the cocina object's structural metadata. The `Content` moves to the new lock as soon as the cocina object is updated, so that a later failure leaves it mutable and ready to retry. When depositing, it then starts accessioning and only afterwards marks the `Content` as immutable. When saving as a draft, the `Content` stays mutable and moves to the new lock, so that editing continues on it while the version is open; saving the item from the item edit page likewise moves it to the new lock, while depositing from there discards it (and any changes that were not staged). The mutable `Content` also holds the text extraction settings (whether to run OCR and in which languages, and whether to run speech to text), which are passed to accessioning. `Sdr::TextExtraction` decides from the content type which text extraction applies: OCR for books, images and documents, and speech to text for media (behind the `feature_flags.speech_to_text_workflow` setting). Accessioning then starts `ocrWF` or `speechToTextWF`, as the text extraction bulk action does directly. Discovery and staging run in the background, and `Content` tracks their progress with state machines so the UI can reflect them.

Canceling manage files discards the unsaved changes by rebuilding the mutable `Content`'s structure from the cocina object, keeping the `Content` itself (and so its text extraction settings) and marking the files that are in the staging folder as staged. It is not possible while the `Content` is staging or discovering, or after staging failed (when the `Content` is the only record of where the files that were not staged are). Deleting a staged file while managing files keeps its staged copy, since the cocina object still references it until the next staging, which deletes the staged files that the `Content` no longer references.

Discarding a draft from the item edit page discards the open version in SDR (a first version cannot be discarded), then deletes the mutable `Content` and every file staged for the object, since staged files belong only to the open version.

Since a `Content` is only ever used for the cocina object's current lock, `Content`s for a lock that is no longer current are deleted by a daily scheduled job (`ContentCleanupJob`, configured in `config/recurring.yml`) once they are a few days old.

A staging failure is recorded on the `Content` (rather than raised), so the object page shows it until it is superseded. Staging is retried by staging the same mutable `Content` again, which resumes where the failure left off, since files already copied to staging are skipped. Starting staging for any `Content` of an object clears earlier failures for that object's other `Content`s.

Staging copies files to the deposit staging location for single-item deposit, or the assembly location for Multi-Item Deposit. Once an object has staged files, later staging continues in that location (so that its files are not split, since assembly reads only the first location with the object's files), and accessioning looks in both. Geo objects and web archive seeds are always staged to the assembly location, since their assembly reads only there; files already staged in the deposit staging location are moved there (replacing any already in the assembly location) when such an object is staged or accessioned, e.g., after an item becomes geo. An object deposited without staged files still gets an (empty) staging folder in the location it would stage to, since assembly requires one.

## Discovery

Search results are restricted to objects readable by the current user's effective workgroups (logged in or impersonated).`Permissions::UserScope` resolves permissions from PostgreSQL, and `Search::PermissionFilter` constructs a Solr filter over the object ID, collection IDs, and APO ID using the same rules as `ObjectPolicy#show?`. Its editable mode uses the rules of `ObjectPolicy#edit?` instead, so that collection selects offer only the collections the user may add items to.

In addition to supporting discovery of items (DROs, collections, and admin policies), the discovery system:
* Supports search of field values. So, for example, in addition to returning a list of item results, a search from the home page will also return a list of matching projects. (This is a list of projects that match the query, not project facets.)
* Is optimized for slow searching / faceting (1) by asynchronously loading some search results and facets (2) by splitting up searching for item results and a small number of primary facets from the rest of the facets (secondary facets)/

### Search forms and views
A search is represented by a search form. `SearchForm` is an abstract base class holding the attributes that determine *which objects match* (the query and all of the facet fields). Each **view** of a search is a subclass:

* `ResultsSearchForm` - the search results view (`/search`). Adds the attributes that only affect how matching objects are presented as a list: `page` and `sort`.
* `AdvancedSearchForm` - a separate Boolean search page (`/advanced_search`). It uses eDisMax with explicit Boolean operators, while ordinary keyword searches retain DisMax. The entire expression is one current filter; field expressions do not select facet values.
* `WorkflowGridSearchForm` - the workflow grid / workflow status view (`/workflow_grid`). See [Workflow grid](#workflow-grid).

A form's **class** is what identifies its view; there is deliberately no `view` attribute, so there is only one source of truth. Views differ in behavior via capability predicates on the form (`pinnable?`, `sortable?`, `item_results?`) rather than via type checks in components.

Because both views share the same query attributes and the same facet UI, components build links by handing a form to `url_for` rather than naming a route: `resolve` in `config/routes.rb` maps each form class to its view's route, so `url_for(search_form.with(...))` keeps the user in whichever view they are already in. `SearchForm#with`, `#without` and `#as` return new forms (they never mutate), dropping any attribute the target class does not declare - so a facet link that resets `page` works unchanged on a view that has no paging.

Which form class a request builds is determined by the **route**, not by a param: every route that builds a search form is declared under a `scope defaults: { view_form: ... }`, and `SearchFormConcern` maps that to a form class.

The following will help illustrate the discovery system components involved for a search from the home page:
1. The search form is rendered from `ResultsSearchForm`.
2. The user enters a query in the search form and starts the search.
3. The page is rendered with:
  * An async turbo frame for items and primary facets.
  * An async turbo frame for secondary facets.
  * Async turbo frames for each of field value types (e.g., projects).
  * Empty divs for each non-lazy (fast!) facet (e.g., object types).
  * Async turbo frames for each lazy (slow!) facet (e.g., project tags).
4. The items async turbo frame for items calls `Search::ItemsController.index`. This invokes the items searcher (`Searchers::Item`) which queries Solr and returns `SearchResults::Items` (a wrapper around the Solr response). The rendered response includes:
  * The item search results
  * Turbo stream replace elements (`<turbo-stream action="replace">`) for the primary facets containing the facet content. When rendering the page, Turbo replaces the empty divs with the facet content.
5. Concurrently, the secondary facets async turbo frame calls `Search::ItemsController.secondary_facets`. This invokes the secondary facets searcher (`Searchers::SecondaryFacet`) which queries Solr and returns `SearchResults::Items`. The rendered response includes turbo stream replace elements for the secondary facets containing the facet content.
5. Concurrently, each of the async field value turbo frames calls the appropriate search controller (e.g., `Search::ProjectsController.index`). This invokes `Searchers::Tag` with the field being searched, which queries Solr and returns `SearchResults::FacetValues` (a wrapper around the Solr response). The rendered response includes the field value search results (e.g., a list of projects).
6. Concurrently, each of the lazy facet async turbo frames calls the facet's endpoint (e.g., `/search/project_facets` for the projects facet), served by `Search::FacetsController`. This invokes the facets searcher (`Searchers::Facet`, or `Searchers::HierarchicalFacet` for hierarchical facets) which queries Solr and returns `SearchResults::FacetCounts` (a wrapper around the Solr response). The rendered response includes the facet content.

Notes:
* On the home page, items AND field values are searched. Once the user has selected facets, ONLY items are searched.
* Field value search is implemented as a Solr facet query: it asks Solr which values of a field match the query rather than which documents do. This is why the result wrapper is named `SearchResults::FacetValues` - the name describes the Solr payload being unwrapped, not the feature. The feature is field value search, and the components that render it are named for field values rather than facets.
* By default, multiple values selected from the same facet are ANDed (including for dynamic and exclude selections), so facet counts reflect the current selection. Excluded values remain listed so that they can be un-excluded.
* Facets configured with `operator: :or` (the checkbox facets, e.g., object types) OR their selected values instead. Their counts ignore the facet's own selection, so that all values remain selectable, and their selected values are displayed as a single current filter (e.g., "Object types ❯ item OR collection").
* Putting Turbo stream replace elements directly in HTML is not a typical pattern for turbo streams.

### Debugging
To view the Solr response for all Solr requests made to render a page, add `debug=true` to the URL.

The Solr requests will be executed with `debugQuery=true`, so the response will include debugging informations
including the amount of time to execute each part of the query / each facet.

### Facet configuration
Each facet is a `Search::Facets::Config` constant, and that configuration is the single source for how the facet is queried, loaded, routed, and rendered:
* `Search::Facets::SIDEBAR` lists the facets shown in the sidebar, in display order. Each one's `loading` says when it loads: `:primary` (with the item results), `:secondary` (with the secondary facets), or `:lazy` (its own turbo frame request, for slow facets). Placeholders, Solr facet requests, and turbo stream replacements are all derived from these.
* Every config is used for filtering (`Search::ItemQueryBuilder`) and for describing a search (`Search::Serializer`), in the order the constants are defined.
* A facet with a `facet_resource` gets its endpoints (`index`, and `children` / `search` if `facet_children` / `facet_search`) drawn in the `:search_endpoints` routing concern, served by `Search::FacetsController` for every search view.
* The facet component is chosen from the config by `Search::ConfiguredFacetComponent`: a checkbox facet for `operator: :or`, a dynamic facet for `dynamic_facet` (with date range inputs given `date_from_form_field` / `date_to_form_field`), a hierarchical facet for `hierarchical_field`, and otherwise a basic facet (with paging, search, and exclude as configured).

### Adding a facet
1. Add an attribute for the facet to `SearchForm`.
2. Add any new solr fields to `Search::Fields`.
3. Add a configuration constant to `Search::Facets`. This must include the `form_field`, `field`, and `loading` attributes. Use `loading: :lazy` for slow facets; a lazy facet also needs a `facet_resource` and `facet_index: true`.
4. Add the facet to `Search::Facets::SIDEBAR` in display order.
5. Optionally, add a label for the facet to `en.yml`.

### Adding paging to a facet
Add a `facet_resource` (e.g., `:mimetype_facets`) and `facet_index: true` to the configuration constant in `Search::Facets`.

### Adding facet search to a facet
Add a `facet_resource` and `facet_search: true` to the configuration constant in `Search::Facets`.

### Composite (label + druid) facets
Some facets need to filter on a unique identifier (a druid) but display a human-friendly, searchable label (a title) — e.g., the APO and Collections facets. A title isn't unique, so faceting directly on the display value of the facet (like most facets do) would be ambiguous. Instead, DSA indexes a composite Solr field whose values are `"<label>:<druid>"` (see`Indexing::CompositeFacetValue` in dor-services-app), and the APO and Collection facet (and links) are built using that composite field.

### Making a facet hierarchical
Add `hierarchical_field`, a `facet_resource`, and `facet_children: true` to the configuration constant in `Search::Facets`. Currently only lazy facets can be hierarchical.

Note:
* Hierarchical faceting requires 2 separate fields, each which has a specific format.

### Making a dynamic facet
Dynamic facets have facet values that are the result of a specified query. Add `dynamic_facet` to the configuration constant in `Search::Facets`.

### Making a dynamic facet support a user-supplied date range
Dynamic facets may optionally have a date range filter (where the user specifies a date from and/or date to). See, for example, the "Earliest accessioned" facet.

1. Add `*_from` and `*_to` attributes to `SearchForm`. For example:
```
    attribute :earliest_accessioned_date_from, :date, default: nil
    attribute :earliest_accessioned_date_to, :date, default: nil
```
2. Add `date_from_form_field`, `date_to_form_field`, and `field` to the configuration constant in `Search::Facets`.

### Adding exclude (query negation) to a facet
Currently, excluding is only available for basic facets (i.e., not hierarchical, dynamic, checkbox, etc.).

1. Add an attribute (`*_exclude`) for the facet exclude to `SearchForm`.
2. Assign the attribute name to `exclude_form_field` for the configuration constant in `Search::Facets`.

### Adding a field to item search results
1. Add any new solr fields to `Search::Fields`.
2. Add the field to `fl` in `Searchers::Item.solr_request`.
3. Possibly add a method to `SearchResults::Item`. See description of how missing methods are handled.
4. Display the field in `Search::ItemResultComponent`.

### Workflow grid
The workflow grid (labeled "Workflow status") is a view of the current search. It displays workflow process counts for the objects matching the search, and renders the same layout, current filters, and facet sidebar as the search results view - so the search can be refined from the grid exactly as it can from the results.

* The grid's search is `WorkflowGridSearchForm`.
* The grid loads in two phases: `/workflow_grid` renders placeholders, then a turbo frame requests `/workflow_grid?...&placeholder=false` for the real data.
* The facets in the sidebar come from `Search::ItemsController#secondary_facets`. The two primary facets (object types and content types) normally ride along with the item results query, which the grid does not render, so `Searchers::SecondaryFacet` adds them for any form where `item_results?` is false.

### Adding sort options to search results
1. Add any new solr fields to `Search::Fields`.
2. Add a sort constant for the sort config to `Search::SortOptions`
3. Add the new search, in the expected order to the `sort_options` in `Search::SortComponent`

## Bulk actions

### Adding a bulk action

A bulk action is defined by its configuration in `services/bulk_actions.rb`. Each configuration with a form gets `new` and `create` routes (generated in `routes.rb`) handled by `BulkActions::FormsController`, and is listed in its section of the new bulk actions page.

1. Add a job that is a subclass of `DruidsJob` (or other bulk action superclasses) and a test. Each job item checks the user's permission for its object (see `CODING_STANDARDS.md`). A job item that changes a cocina model saves it with `BaseJobItem#save_model_and_deposit!`, which opens a version if needed and deposits when the user chose to close versions.
2. Add configuration to `services/bulk_actions.rb`, in the order it is listed within its section. Set `close_version` if the form offers depositing once the action is complete, and `admin_policy_rule` if only some users may run it.
3. If the job needs parameters beyond the druids (or CSV) and the form's attributes, add a form (a subclass of `BulkActions::BasicForm` or `BulkActions::BasicCsvForm`) and override `job_params` where its attributes don't map directly to the job's parameters.
4. If the form has fields beyond the druid list (or CSV upload), add a `views/bulk_actions/<bulk action>/new.html.erb` view; otherwise the default view is used. Add a controller (a subclass of `BulkActions::FormsController`, named by the configuration's `controller`) only when rendering the form needs something the form can't provide, such as options limited to what the user may edit.
5. The bulk action forms request spec covers rendering every form and submitting those that use `BulkActions::BasicForm`. For other forms, add a request spec, or a system spec only when the form depends on JavaScript (e.g., multi-selects or fields toggled by other fields). (The job can be stubbed out.)

## Design
Design standards (layout, components, typography, color, accessibility, copy) are in `DESIGN_STANDARDS.md`. Deliberate deviations are marked in the code with a `Design standard deviation:` comment.
