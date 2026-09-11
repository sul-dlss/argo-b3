import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

// Refresh a page on an interval.
export default class extends Controller {
  static values = {
    interval: Number
  }

  connect () {
    this.href = window.location.href
    if (this.reloadTimeout) return

    this.scheduleReload()
  }

  disconnect () {
    if (this.reloadTimeout) {
      clearTimeout(this.reloadTimeout)
      this.reloadTimeout = null
    }
  }

  // Refreshes the whole page (via Turbo's morph-based page refresh) on each interval.
  scheduleReload = () => {
    this.reloadTimeout = setTimeout(() => {
      if (this.href === window.location.href && document.visibilityState === 'visible') {
        Turbo.session.refresh(this.href)
      }

      this.scheduleReload()
    }, this.intervalValue)
  }
}
