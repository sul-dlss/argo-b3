import { Controller } from '@hotwired/stimulus'

const PRESERVED_CLASSES = ['nav-link', 'tab-pane', 'accordion-button', 'accordion-collapse']

// Controller for the Cocina model show page.
export default class extends Controller {
  static values = {
    interval: Number,
    stagger: Number
  }

  connect () {
    document.addEventListener('turbo:before-morph-attribute', this.preserveTab)
    document.addEventListener('turbo:before-fetch-response', this.handleFrameResponse)
    document.addEventListener('turbo:before-frame-render', this.preventFailedFrameRender)
    document.addEventListener('turbo:frame-missing', this.handleMissingFrame)

    this.href = window.location.href
    this.frameReloadTimeouts = []
    if (this.reloadTimeout) return

    // Use a single recursive timer so each refresh cycle waits for the prior
    // staggered frame reloads to be scheduled before starting the next cycle.
    // Reloads are staggered to allow the Solr docs to be cached after the first request
    // and to reduce bursts of requests when multiple frames are present.
    this.scheduleReloadCycle()
  }

  disconnect () {
    if (this.reloadTimeout) {
      clearTimeout(this.reloadTimeout)
      this.reloadTimeout = null
    }

    // Clear any pending staggered frame reloads when leaving the page.
    this.frameReloadTimeouts.forEach((timeoutId) => clearTimeout(timeoutId))
    this.frameReloadTimeouts = []

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

  scheduleReloadCycle = () => {
    const frames = Array.from(document.querySelectorAll('turbo-frame'))
    const cycleDelay = this.intervalValue + (Math.max(frames.length - 1, 0) * this.staggerValue)

    this.reloadTimeout = setTimeout(() => {
      if (this.href !== window.location.href) return

      this.frameReloadTimeouts = []

      // Reload frames one at a time to spread out requests and reduce bursts.
      // Skip frames containing forms — reloading would discard the user's unsaved input.
      frames.filter(frame => !frame.querySelector('form')).forEach((frame, index) => {
        const timeoutId = setTimeout(() => {
          frame.reload()
        }, index * this.staggerValue)

        this.frameReloadTimeouts.push(timeoutId)
      })

      this.scheduleReloadCycle()
    }, cycleDelay)
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
