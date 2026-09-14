import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

// Refresh a page on an interval.
export default class extends Controller {
  static values = {
    interval: Number
  }

  connect () {
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
  // Refreshes are skipped while the user is on a different tab.
  scheduleReload = () => {
    this.reloadTimeout = setTimeout(() => {
      if (document.visibilityState === 'visible') {
        Turbo.session.refresh(window.location.href)
      }

      this.scheduleReload()
    }, this.intervalValue)
  }
}
