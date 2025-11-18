[![CircleCI](https://dl.circleci.com/status-badge/img/gh/sul-dlss/argo-b3/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/sul-dlss/argo-b3/tree/main
)
[![Test Coverage](https://codecov.io/github/sul-dlss/argo-b3/graph/badge.svg?token=9Y9EL3VG6I)](https://codecov.io/github/sul-dlss/argo-b3)

# README

## Development

To connect to production Solr

```
ssh -L 8985:sul-solr-prod-a.stanford.edu:80 lyberadmin@argo-prod-02.stanford.edu
```

In a separate terminal window:
```
SETTINGS__SOLR__URL=http://localhost:8985/solr/argo_prod bin/dev
```

### Linters

To run all configured linters, run `bin/rake lint`.

To run linters individually, run which ones you need:

* Ruby code: `bin/rubocop` (add `-a` flag to autocorrect violations)
* ERB templates: `bin/erb_lint --lint-all --format compact` (add `-a` flag to autocorrect violations)
* ERB templates: `bin/herb analyze app --no-log-file`
* JavaScript code: `yarn run lint` (add `--fix` flag to autocorrect violations)
* SCSS stylesheets: `yarn run stylelint` (add `--fix` flag to autocorrect violations)

## Deployment

NOTE: The application is deployed continuously by our on-prem Jenkins service (`sul-ci-prod`) to the `poc` environment on every merge to `main`. See `Jenkinsfile` for how that is wired up.

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

## Discovery
In addition to supporting discovery of items (DROs, collections, and admin policies), the discovery system:
* Supports search of field values. So, for example, in addition to returning a list of item results, a search from the home page will also return a list of matching projects. (This is a list of projects that match the query, not project facets.)
* Is optimized for slow searching / faceting by asynchronously loading some search results and facets.

The following will help illustrate the discovery system components involved for a search from the home page:
1. The search form is rendered from `Search::Form`.
2. The user enters a query in the search form and starts the search.
3. The page is rendered with:
  * An async turbo frame for items.
  * Async turbo frames for each of field value types (e.g., projects).
  * Empty divs for each non-lazy (fast!) facet (e.g., object types).
  * Async turbo frames for each lazy (slow!) facet (e.g., project tags).
4. The async turbo frame for items calls `Search::ItemsController.index`. This invokes the items searcher (`Searchers::Item`) which queries Solr and returns `SearchResults::Items` (a wrapper around the Solr response). The rendered response includes:
  * The item search results
  * Turbo stream replace elements (`<turbo-stream action="replace">`) for each of the non-lazy facets containing the facet content. When rendering the page, Turbo replaces the empty divs with the facet content.
5. Concurrently, each of the async field value turbo frames calls the appropriate search controller (e.g., `Search::ProjectsController.index`). This invokes the appropriate searcher (e.g., `Searchers::Project`) which queries Solr and returns `SearchResults::FacetValues` (a wrapper around the Solr response). The rendered response includes the field value search results (e.g., a list of projects).
6. Concurrently, each of the lazy facet async turbo frames calls the appropriate endpoint on the `Search::FacetsController` (e.g., `project_tags` for the projects facet). This invokes the facets searcher (`Searchers::Facet`) which queries Solr and returns `SearchResults::FacetCounts` (a wrapper around the Solr response). The rendered response includes the facet content.

Notes:
* On the home page, items AND field values are searched. Once the user has selected facets, ONLY items are searched.
* Putting Turbo stream replace elements directly in HTML is not a typical pattern for turbo streams.

### Debugging
To view the Solr response for all Solr requests made to render a page, add `debug=true` to the URL. 

The Solr requests will be executed with `debugQuery=true`, so the response will include debugging informations
including the amount of time to execute each part of the query / each facet.

### Adding a lazy async facet
The lazy async pattern should be used for slow facets. Each of these facets involves a separate query to Solr.

1. Add an attribute for the facet to `Search::ItemForm`.
2. Add a `<turbo-frame>` for the facet to `Search::FacetsSectionComponent`.
3. Add a new `*_facets` resource to `routes.rb`. See for example, `:tag_facets`. Add collection routes depending on whether the facet is hierarchical, supports search, etc.
4. Add a new `Search::*FacetsController` and add a request spec. See for example, `Search::TagFacetsController`. This should implement the `index` method, as well as any additional collection routes.
5. Add the facet to `Search::ItemQueryBuilder.filter_queries` and add a spec to `spec/services/search/item_query_builder_spec.rb`.
6. Optionally, add a label for the facet to `en.yml`.

### Adding a non-lazy sync facet
The non-lazy sync pattern should be used for fast facets. The facet values are retrieved as part of the main query to Solr (i.e., the query that returns the search results).

1. Add an attribute for the facet to `Search::ItemForm`.
2. Add an empty `<div>` for the facet to `Search::FacetsSectionComponent`.
3. Add the facet to the Solr request in `Searchers::Item.solr_request`. This allows specifying sort order, limits, etc.
4. Add a method to `SearchResults::Items` to return the `SearchResults::FacetCounts` for the facet.
5. Add a turbo stream replace element (`<turbo-stream action="replace">`) for the facet to `views/search/items/index.html.erb`.
6. Add the facet to `Search::ItemQueryBuilder.filter_queries` and add a spec to `spec/services/search/item_query_builder_spec.rb`.
7. Optionally, add a label for the facet to `en.yml`.