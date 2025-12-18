import { Controller } from '@hotwired/stimulus'

// Reload the page on an interval
export default class extends Controller {
  static values = {
    interval: Number
  }

  connect () {
    this.href = window.location.href
    if (this.reloadInterval) return
    this.reloadInterval = setInterval(() => {
      if (this.href !== window.location.href) return
      Turbo.visit(window.location.href, { action: 'replace' }) // eslint-disable-line no-undef
    }, this.intervalValue)
  }

  disconnect () {
    if (this.reloadInterval) clearInterval(this.reloadInterval)
  }
}
