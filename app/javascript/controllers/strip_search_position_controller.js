import { Controller } from '@hotwired/stimulus'

// Removes the "search_position" query param from the URL once the page has loaded, without
// triggering a navigation. The position itself is persisted server-side in the last_search cookie
// (see ObjectsController#search_position), so the param only needs to survive the initial request --
// this keeps it out of the visible/bookmarked/shared URL afterward.
//   <div data-controller="strip-search-position">
export default class extends Controller {
  connect () {
    const url = new URL(window.location)
    if (!url.searchParams.has('search_position')) return

    url.searchParams.delete('search_position')
    window.history.replaceState(window.history.state, '', `${url.pathname}${url.search}`)
  }
}
