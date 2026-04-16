import { Controller } from '@hotwired/stimulus'

const PRESERVED_CLASSES = ['nav-link', 'tab-pane', 'accordion-button', 'accordion-collapse']

// Controller for the Cocina model show page.
export default class extends Controller {
  static values = {
    interval: Number
  }

  connect () {
    document.addEventListener('turbo:before-morph-attribute', this.preserveTab)
    document.addEventListener('turbo:before-fetch-response', this.handleFrameResponse)
    document.addEventListener('turbo:before-frame-render', this.preventFailedFrameRender)
    document.addEventListener('turbo:frame-missing', this.handleMissingFrame)

    this.href = window.location.href
    if (this.reloadInterval) return

    // Morph reload every interval to get updates.
    this.reloadInterval = setInterval(() => {
      if (this.href !== window.location.href) return
      document.querySelectorAll('turbo-frame').forEach((frame) => frame.reload())
    }, this.intervalValue)
  }

  disconnect () {
    if (this.reloadInterval) {
      clearInterval(this.reloadInterval)
      this.reloadInterval = null
    }

    document.removeEventListener('turbo:before-morph-attribute', this.preserveTab)
    document.removeEventListener('turbo:before-fetch-response', this.handleFrameResponse)
    document.removeEventListener('turbo:before-frame-render', this.preventFailedFrameRender)
    document.removeEventListener('turbo:frame-missing', this.handleMissingFrame)
  }

  // This preserves the active tab when the page is refreshed
  // by preventing Turbo from morphing the tab list, tab pane, accordion button,
  // and accordion body attributes
  preserveTab = (event) => {
    if (PRESERVED_CLASSES.some((className) => event.target.classList.contains(className))) {
      event.preventDefault()
    }
  }

  // handleFrameResponse, preventFailedFrameRender, and handleMissingFrame work together to prevent 
  // Turbo from rendering an error page in a frame when the server returns an error response. 
  handleFrameResponse = (event) => {
    if (event.target.tagName !== 'TURBO-FRAME') return

    const { fetchResponse } = event.detail

    if (fetchResponse.serverError) {
      event.target.dataset.serverError = 'true'
    } else {
      delete event.target.dataset.serverError
    }
  }

  preventFailedFrameRender = (event) => {
    if (event.target.dataset.serverError === 'true') {
      event.preventDefault()
      delete event.target.dataset.serverError
    }
  }

  handleMissingFrame = (event) => {
    if (event.detail.response.status !== 200) {
      event.preventDefault()
    }
  }
}