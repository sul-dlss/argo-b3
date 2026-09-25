import { Controller } from '@hotwired/stimulus'

// Reload the enclosing turbo-frame after an interval.
// Place on an element inside the frame (rather than on the frame itself) since Turbo only replaces a frame's
// children when rendering a frame response. Each reload renders a new element, which schedules the next reload,
// so reloading stops once the server responds with content that doesn't include this controller.
export default class extends Controller {
  static values = {
    interval: Number
  }

  connect () {
    this.reloadTimeout = setTimeout(() => {
      this.element.closest('turbo-frame')?.reload()
    }, this.intervalValue)
  }

  disconnect () {
    clearTimeout(this.reloadTimeout)
  }
}
