import { Controller } from '@hotwired/stimulus'

const PRESERVED_CLASSES = ['nav-link', 'tab-pane', 'accordion-button', 'accordion-collapse']

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
  // by preventing Turbo from morphing the tab list, tab pane, accordion button,
  // and accordion body attributes
  preserveTab (event) {
    if (PRESERVED_CLASSES.some((className) => event.target.classList.contains(className))) {
      event.preventDefault()
    }
  }
}
