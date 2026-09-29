import { Controller } from '@hotwired/stimulus'

// Reload the enclosing turbo-frame after an interval.
// Place on an element inside the frame (rather than on the frame itself) since Turbo only replaces a frame's
// children when rendering a frame response. Each reload renders a new element, which schedules the next reload,
// so reloading stops once the server responds with content that doesn't include this controller.
export default class extends Controller {
  static values = {
    interval: Number,
    // Optional url to reload from instead of the frame's current src.
    url: String
  }

  connect () {
    this.reloadTimeout = setTimeout(() => this.reload(), this.intervalValue)
  }

  reload () {
    const frame = this.element.closest('turbo-frame')
    if (!frame) return

    // Setting src loads the frame from the url; once src is the url, reloading is sufficient.
    if (this.hasUrlValue && this.absoluteUrl(this.urlValue) !== this.absoluteUrl(frame.src)) {
      frame.src = this.urlValue
    } else {
      frame.reload()
    }
  }

  absoluteUrl (url) {
    return new URL(url, window.location.href).href
  }

  disconnect () {
    clearTimeout(this.reloadTimeout)
  }
}
