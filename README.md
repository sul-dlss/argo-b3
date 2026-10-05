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

### Using resources from deployed environments

To avoid having to bootstrap local resources or to test with real objects, sometimes it is useful to point the local development environment at deployed resources (e.g., Solr, DSA). Note that these connections are read/write, so be cautious with interactions with deployed environments, especially prod.

Any of the below approaches can be combined (and usually will be).

#### Solr

To connect to production Solr (there is only a production environment for Solr):

```
ssh -L 8990:sul-solr-prod-a.stanford.edu:80 lyberadmin@argo-b3-prod-a.stanford.edu
```

In a separate terminal window:
```
SETTINGS__SOLR__URL=http://localhost:8990/solr/argo_qa bin/setup
```
to connect to the Argo QA Solr index. (Alternatively, you can connect to the stage Solr index with `argo_stage` or production with `argo_prod`.)

#### DSA
[Obtain a token for the DSA instance](https://github.com/sul-dlss/dor-services-app#authentication) and then:
```
SETTINGS__DOR_SERVICES__URL='https://dor-services-qa-lb.stanford.edu' SETTINGS__DOR_SERVICES__TOKEN=hbGcifaketokenOiJIUzI1NiJ9.jbvl5uai9y2MF7_nFqYrcewO4uKJ8tLY2A69b bin/setup
```

#### SDR Event / RabbitMQ
Argo publishes events (e.g., permission changes) to RabbitMQ, where they are consumed by DSA. Publishing is
disabled by default (`Settings.rabbitmq.enabled`) so that a local RabbitMQ is not required. To publish events
to a RabbitMQ instance:
```
SETTINGS__RABBITMQ__ENABLED=true SETTINGS__RABBITMQ__HOSTNAME='sul-rabbitmq-qa-a.stanford.edu' bin/setup
```

#### PresCat
[Obtain a token for the PresCat instance](https://github.com/sul-dlss/preservation_catalog#authn) and then:

```
SETTINGS__PRESERVATION_CATALOG__URL='https://preservation-catalog-qa.stanford.edu' SETTINGS__PRESERVATION_CATALOG__TOKEN='fgJhbGcfaketokenJ9.eyJzdWJhcmdvIn0.FhjtP5vOd1xIX7h6oRBNZrf' bin/setup
```

#### Other
```
SETTINGS__PURL_FETCHER__URL='https://purl-fetcher-stage.stanford.edu' SETTINGS__STACKS__URL='https://stacks-stage.stanford.edu/image' bin/setup
```

### Development script for running locally connecting to remote services

For running code in localhost pointing to real data on a server environment, `bin/dev-server` will facilitate the setup described above.

1. Ensure you are on VPN, have a valid kerberos ticket, and docker desktop client is running.
2. Running `bin/dev-server` sets up the jumphost (if needed), opens a solr tunnel in the background, ensures required docker containers are up, configures the environment variables for connection to qa/stage/prod services, and starts the localhost server.  The script can be passed a parameter of "stage", "qa" or "prod" and will auto-configure the service URLs (e.g. `bin/dev-server stage`).  It defaults to "qa" if no environment is passed.
3. In order to authenticate with DSA and Prescat (to display and edit objects),, you will need valid DSA and Prescat tokens for the remote environments you are connected to.  While you can pass these into the bin script via env variables as described in the sections above, it is easier to setup a `.env-server` file in the root of the app, and put the tokens in there as env variables.  The `.env-server` file will be gitignored and automatically picked up by the `bin/dev-server` script. The `.env-server` file can also contain the service URLs as env variables if you do not want them automatically configured by the script.  If the tokens are different per environment (e.g. stage vs qa vs prod), you will need to change them in the `.env-server` file (e.g. comment/uncomment out as needed) before starting `bin/dev-server`.

### Bootstrapping an APO and collection

To create an APO for local development, run `bin/rake development:bootstrap_apo`. Optionally provide a title with `TITLE="My APO"`; otherwise a random title is generated.

To create a collection, run `bin/rake "development:bootstrap_collection[druid:...]"`, passing the APO druid. Optionally provide a title with `TITLE="My Collection"`; otherwise a random title is generated.

### Linters

To run all configured linters, run `bin/rake lint`.

To run linters individually, run which ones you need:

* Ruby code: `bin/rubocop` (add `-a` flag to autocorrect violations)
* ERB templates: `bin/erb_lint --lint-all --format compact` (add `-a` flag to autocorrect violations)
* ERB templates: `bin/herb analyze app`
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
  * For local deploys, `bin/kamal-otk` loads any missing required deploy secrets from Vault before invoking Kamal.
* The Dockerfile configures the lyberadmin (50:503) user to match the host server.
* `/workspace/bulk` and `/var/log/argo` are shared with the containers.
* The docker image is built on the stage server (AMD64) for all environments to avoid emulation on the developer Mac. Sharing one builder keeps its layer cache warm across environments.


### Deploy

To build and deploy the local, committed code:

```
bin/kamal-otk qa deploy
```

For local deploys, `bin/kamal-otk` loads required deploy secrets from Vault only when they are missing from the current environment, then runs Kamal.

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
* Forms that create or edit a cocina object (e.g., `ItemForm`, `ContentsItemForm`) subclass the relevant cocina model (e.g., `CocinaModels::Dro`) rather than `ApplicationForm`. This allows them to reuse the cocina model's attributes, mapping, mutation, and persistence (`create!` / `save!`), while adding form-only concerns: attributes that exist only to drive the UI (e.g., choosing between providing or generating a source ID), conditional validations, and callbacks that derive cocina model attributes from those form-only attributes before validation. Different editing contexts for the same type of object get their own form (and endpoint) so that each only permits and validates the attributes it edits.
* All other forms subclass `ApplicationForm` (e.g., `TicketTagForm`, `ReleaseTagsForm`, search forms, bulk action forms). These are not backed by a cocina object, though some still perform an action (e.g., `ReleaseTagsForm#create!`).

## Structural metadata
Unlike other parts of a cocina object, structural metadata (file sets and files) is not wrapped by a cocina model. Instead, it is held in the DB as Active Record models, since it can be large and is edited incrementally (e.g., uploading files, discovering files, reordering file sets) over many requests:
* `Content` - the structure of a DRO for a particular version of the cocina object, identified by the druid and the cocina object's lock.
* `ContentFileSet` - a cocina file set, ordered within the `Content`.
* `ContentFile` - a cocina file as it occurs within a particular file set, ordered within the `ContentFileSet` and holding the file-level attributes (e.g., access, preserve / shelve / publish).
* `ContentFileBinary` - the physical file, identified by its filepath. Since the same file may be referenced by more than one file set, a binary may have multiple `ContentFile`s. A binary that is not referenced by any `ContentFile` ("unassociated") is not part of the structure (e.g., a file that has been uploaded but not yet placed in a file set).

A `Content` is either **immutable**, in which case it exactly reflects the structural metadata of the cocina object version identified by its lock (e.g., for display and structural CSV export), or **mutable**, in which case it is being edited and may have deviated from the cocina object.

Mapping to and from cocina structural metadata:
* `Contents::Builder` builds a `Content` from a cocina object's structural metadata, deduplicating files with the same filepath into a single `ContentFileBinary`.
* `CocinaObjectMutators::StructuralMutator` rebuilds a cocina object's structural metadata from a `Content`. Before doing so, it validates that every file set, file, and binary is ready for deposit (the `:deposit` validation context); earlier in the editing flow these records are allowed to be incomplete.

Each `ContentFileBinary` records where its physical file is located (`file_location`). Files move from where they were added (`attached` for files uploaded via the browser and stored with Active Storage, `mount` for files on a mounted filesystem, and `globus` for files on the Globus filesystem) to `stage`, and binaries built from an existing cocina object are `deposited` (already accessioned and stored in preservation / stacks).

Files are added to a mutable `Content` as unassociated binaries, either by upload or by **discovery** (`DiscoverFilesJob` recursively lists the files in a directory on a mount). Ignored files (e.g., `.DS_Store`) never become binaries. The `Contents::Populators` then structure the unassociated binaries into file sets and files, using a strategy appropriate to the content type (e.g., for a book, files that share a filename apart from the extension, such as the image and OCR for a page, are grouped into one file set). `Contents::PopulatorSelector` picks the populator and falls back to one file set per file when the content type's populator cannot handle the files.

**Staging** (`StageFilesJob`) deposits a mutable `Content`. It mints identifiers for new file sets and files, computes digests / size / mime type, copies the files to the staging location, and updates the cocina object's structural metadata. It then marks the `Content` as immutable for the new lock and optionally starts accessioning. Discovery and staging run in the background, and `Content` tracks their progress with state machines so the UI can reflect them.

## Discovery

Search results are restricted to objects readable by the current user's effective workgroups (logged in or impersonated).`Permissions::UserScope` resolves permissions from PostgreSQL, and `Search::PermissionFilter` constructs a Solr filter over the object ID, collection IDs, and APO ID using the same rules as `ObjectPolicy#show?`.

In addition to supporting discovery of items (DROs, collections, and admin policies), the discovery system:
* Supports search of field values. So, for example, in addition to returning a list of item results, a search from the home page will also return a list of matching projects. (This is a list of projects that match the query, not project facets.)
* Is optimized for slow searching / faceting (1) by asynchronously loading some search results and facets (2) by splitting up searching for item results and a small number of primary facets from the rest of the facets (secondary facets)/

### Search forms and views
A search is represented by a search form. `SearchForm` is an abstract base class holding the attributes that determine *which objects match* (the query and all of the facet fields). Each **view** of a search is a subclass:

* `ResultsSearchForm` - the search results view (`/search`). Adds the attributes that only affect how matching objects are presented as a list: `page` and `sort`.
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
6. Concurrently, each of the lazy facet async turbo frames calls the appropriate `Search::*FacetsController` (e.g., `Search::ProjectFacetsController` for the projects facet). This invokes the facets searcher (`Searchers::Facet`, or `Searchers::HierarchicalFacet` for hierarchical facets) which queries Solr and returns `SearchResults::FacetCounts` (a wrapper around the Solr response). The rendered response includes the facet content.

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

### Adding a lazy async facet
The lazy async pattern should be used for slow facets. Each of these facets involves a separate query to Solr.

1. Add an attribute for the facet to `SearchForm`.
2. Add any new solr fields to `Search::Fields`.
3. Add a `Search::LoadingFacetFrameComponent` for the facet to `Search::FacetsSectionComponent`. This adds a placeholder `turbo-frame` that will be replaced with the facet content.
4. Add a new `*_facets` resource to the `:search_endpoints` routing concern in `routes.rb`, providing the `index` route. See for example, `:tag_facets`.
5. Add a new `Search::*FacetsController` and add a request spec. For simple (non-hierarchical) paged facets, call `serves_facet <Config>` — the `index` and `search` actions are inherited from `FacetsApplicationController`. For hierarchical facets, implement a custom `index` and `children` method. See for example, `Search::TagFacetsController`.
6. Add a configuration constant to `Search::Facets`. This must include the `form_field` and `field` attributes, plus `facet_resource` (the routing resource added in step 4) and `facet_index: true`.
7. Add the facet to `Search::ItemQueryBuilder::FACETS`.
8. Optionally, add a label for the facet to `en.yml`.

Note:
* Currently, the only lazy async facets that are supported are for hierarchical facets. However, additional types could be supported by provided alternatives to `Search::HierarchicalFacetFrameComponent` (which is rendered in `Search::*FacetsController.index`)

### Adding a non-lazy sync facet
The non-lazy sync pattern should be used for fast facets. The facet values are retrieved as part of the main query to Solr (i.e., the query that returns the search results).

1. Add an attribute for the facet to `SearchForm`.
2. Add any new solr fields to `Search::Fields`.
3. Add a configuration constant to `Search::Facets`. This must include the `form_field` and `field` attributes.
4. Add a `Search::LoadingFacetDivComponent` for the facet to `Search::FacetsSectionComponent`. This adds a placeholder `div` that will be replaced with the facet content.
5. Add the facet to the Solr request in `Searchers::Item::FACETS` or `Searchers::SecondaryFacet::FACETS`.
6. Add a turbo stream replace element (`Search::FacetTurboStreamReplaceComponent`) for the facet to `views/search/items/index.html.erb` or `views/search/items/secondary_facets.html.erb`. This allows specifying the type of facet component to use to render the facet (e.g., a `Search::CheckboxFacetComponent`).
7. Add the facet to `Search::ItemQueryBuilder::FACETS`.
8. Optionally, add a label for the facet to `en.yml`.

### Adding paging to a facet
1. Add a new `*_facets` resource to the `:search_endpoints` routing concern in `routes.rb`. See for example, `:mimetype_facets`. This only needs to provide an `index` route.
2. Add a new `Search::*FacetsController` that calls `serves_facet <Config>` and add a request spec using the `'a simple facet controller'` shared examples. See for example, `Search::MimetypeFacetsController`. The `index` action is inherited from `FacetsApplicationController`.
3. Add `facet_resource` and `facet_index: true` to the configuration constant in `Search::Facets`.

Note:
* Some of these steps may already have been performed, e.g., for a lazy, async facet.

### Adding facet search to a facet
1. Add a new `*_facets` resource to the `:search_endpoints` routing concern in `routes.rb`. See for example, `:project_facets`. This should provide a `search` route.
2. Add a new `Search::*FacetsController` and add a request spec. See for example, `Search::ProjectFacetsController`. The `search` action is inherited from `FacetsApplicationController`; no custom implementation is needed unless the controller also has a custom `index`.
3. Add `facet_resource` and `facet_search: true` to the configuration constant in `Search::Facets`.

Note:
* Some of these steps may already have been performed, e.g., for a lazy, async facet.

### Composite (label + druid) facets
Some facets need to filter on a unique identifier (a druid) but display a human-friendly, searchable label (a title) — e.g., the APO and Collections facets. A title isn't unique, so faceting directly on the display value of the facet (like most facets do) would be ambiguous. Instead, DSA indexes a composite Solr field whose values are `"<label>:<druid>"` (see`Indexing::CompositeFacetValue` in dor-services-app), and the APO and Collection facet (and links) are built using that composite field.

### Making a facet hierarchical
1. Add a new `*_facets` resource to the `:search_endpoints` routing concern in `routes.rb`. See for example, `:tag_facets`. This should provide the `children` route.
2. Add a new `Search::*FacetsController` and add a request spec. See for example, `Search::TagFacetsController`. This should implement the `children` method.
3. Add `facet_children_path_helper` and `hierarchical_field` to the configuration constant in `Search::Facets`.
4. Change the facet to be rendered with the hierarchical facet component. For a lazy async facet, render a `Search::HierarchicalFacetFrameComponent` in `Search::*FacetsController.index`. For a non-lazy sync facet, set the turbo stream replace element in `views/search/items/index.html.erb` to render a `Search::HierarchicalFacetComponent`.

Note:
* Hierarchical faceting requires 2 separate fields, each which has a specific format.

### Making a dynamic facet
Dynamic facets have facet values that are the result of a specified query.

1. Add `dynamic_facet` to the configuration constant in `Search::Facets`.
2. When adding the facet to the Solr request in `Searchers::Item.facet_json` use a `Search::DynamicFacetBuilder`.
3. When adding a method to `SearchResults::Items`, return a `SearchResults::DynamicFacetCounts` for the facet.
4. When adding a turbo stream replace element (`Search::FacetTurboStreamReplaceComponent`) for the facet to `views/search/items/index.html.erb` use a `Search::DynamicFacetComponent`.
5. When adding the facet to `Search::ItemQueryBuilder.filter_queries`, call `dynamic_facet_filter_query()`.

### Making a dynamic facet support a user-supplied date range
Dynamic facets may optionally have a date range filter (where the user specifies a date from and/or date to). See, for example, the "Earliest accessioned" facet.

1. Add `*_from` and `*_to` attributes to `SearchForm`. For example:
```
    attribute :earliest_accessioned_date_from, :date, default: nil
    attribute :earliest_accessioned_date_to, :date, default: nil
```
2. Add `date_from_form_field`, `date_to_form_field`, and `field` to the configuration constant in `Search::Facets`.
3. When adding a turbo stream replace element (`Search::FacetTurboStreamReplaceComponent`) for the facet to `views/search/items/index.html.erb` provide the `date_from_form_field` and `date_to_form_field` to `Search::DynamicFacetComponent`

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

1. Add a job that is a subclass of `DruidsJob` (or other bulk action superclasses) and a test.
2. Add a new resource to `routes.rb` under the `bulk_actions` namespace.
3. Add configuration to `services/bulk_actions.rb`.
4. Add the bulk action to the list of bulk actions in `views/bulk_actions/new.html.erb`.
5. Add a controller for the bulk action that is a subclass of `BulkActionApplicationController`.
6. Add a `new.html.erb` view.
7. Add a system test. (The job can be stubbed out.)

## Conventions

### Dates / times
Application-rendered dates / times should use one of these formats, which are defined in `en.yml`:

* `date_only`: `YYYY-MM-DD` (for example, `2026-07-29`)
* `date_time`: `YYYY-MM-DD HH:MM:SS PT` (for example, `2026-07-29 14:56:58 PT`)

Use the `format_datetime` helper, which defaults to `date_time` and renders values in the "Pacific Time (US & Canada)" time zone. Pass `format: :date_only` for a date without a time. The `PT` label is intentionally used year-round while the underlying time observes daylight saving time.

CSV report values are an exception because Argo receives them as preformatted values from Solr. Machine-readable dates / times, such as Solr query values, repository API values, and HTTP headers, should continue to use the format required by their protocol.

### Notifications

#### Error notifications
The user should be notified of errors using a danger alert.

The danger alert can be triggered with a `flash[:danger]`.

#### Informational notifications
The user should be notified of informational messages (e.g., status updates, success) using disappearing toasts.

Toasts can be triggered with `flash[:toast]` or by broadcasting to the `notifications` channel:
```
component = SdrViewComponents::Elements::ToastComponent.new(title: "#{bulk_action.label} completed",
                                                                  disappearing: true)
      Turbo::StreamsChannel.broadcast_append_to('notifications', bulk_action.user,
                                                target: 'toast-container',
                                                html: ApplicationController.render(component, layout: false))
```

## Design
Where ever possible design components from the [DLSS component style library](https://github.com/sul-dlss/component-library/) and view components from [SDR View Components](https://github.com/sul-dlss/sdr_view_components) should be re-used.

### Responsive design
In general, alternate viewports are supported for "show" pages (e.g., dashboard, object show page) not "form" pages (e.g., single item creation).

All pages should use the default container: `<div class="container">`.

Pages are designed for the following breakpoints / devices:
* `xxl` and `xl`: Monitor
* `lg` and `md`: Tablet
* `sm` and `xs`: Phone
