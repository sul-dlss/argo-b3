import { Controller } from '@hotwired/stimulus'

// Controller for the Cocina model show page.
export default class extends Controller {
  static values = {
    interval: Number
  }

  connect () {
    document.addEventListener('turbo:before-morph-attribute', this.preserveTab)

    this.href = window.location.href
    if (this.reloadInterval) return
    // Morph reload every interval to get updates.
    this.reloadInterval = setInterval(() => {
      if (this.href !== window.location.href) return
      Turbo.visit(window.location.href, { action: 'replace' }) // eslint-disable-line no-undef
    }, this.intervalValue)
  }

  disconnect () {
    if (this.reloadInterval) {
      clearInterval(this.reloadInterval)
      this.reloadInterval = null
    }
    document.removeEventListener('turbo:before-morph-attribute', this.preserveTab)
  }

  // This preserves the active tab when the page is refreshed
  // by preventing Turbo from morphing the tab list and pane attributes.
  preserveTab (event) {
    if (event.target.classList.contains('nav-link') || event.target.classList.contains('tab-pane')) {
      event.preventDefault()
    }
  }
}
