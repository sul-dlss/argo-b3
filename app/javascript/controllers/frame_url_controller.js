import { Controller } from '@hotwired/stimulus'

// Keeps the browser URL in sync with a lazily-loaded turbo-frame's current state, without
// triggering a full page visit.  Useful for controls (e.g. pagination, sorting) that only need to
// update within a single frame but whose state should still be reflected in the URL so that a refresh restores it.
//   <turbo-frame src="/search/items?..." data-controller="frame-url" data-frame-url-path-value="/search"
//                data-action="turbo:frame-load->frame-url#updateURL">
export default class extends Controller {
  static values = { path: String }

  updateURL () {
    const { search } = new URL(this.element.getAttribute('src'), window.location.origin)
    window.history.replaceState(window.history.state, '', `${this.pathValue}${search}`)
  }
}
