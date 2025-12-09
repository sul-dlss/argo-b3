import { Controller } from '@hotwired/stimulus'

// Aborts in-flight turbo frame requests on navigation
// Without this, the user has to wait until all frame requests finished before navigating away.
export default class extends Controller {
  static targets = ['frame']

  connect () {
    this.frameAbortControllers = new Map()
    this.initialized = false
    // Inject our own AbortController into Turbo's fetch options so we can abort later
    this._beforeFetchHandler = (event) => {
      // Only care about frame-driven fetches
      const target = event.target
      if (target && target.tagName === 'TURBO-FRAME') {
        const controller = new AbortController()
        // Replace Turbo's signal with ours so we hold the abort handle
        if (event.detail?.fetchOptions) {
          // Set low priority for frames
          event.detail.fetchOptions.priority = 'low';

          event.detail.fetchOptions.signal = controller.signal
          this.frameAbortControllers.set(target, controller)
        }
      }
    }

    // On navigation away from the page, abort any in-flight frame fetches immediately
    this._beforeVisitHandler = (event) => {
      console.log(this.frameAbortControllers)
      if (event.explicitOriginalTarget.dataset.turboFrame !== '_top') {
        const turboFrame = event.explicitOriginalTarget.closest('turbo-frame')
        console.log(turboFrame)
        console.log(this.frameAbortControllers.get(turboFrame))
      } else {
        console.log('Aborting in-flight frame requests before visit')
        this.frameAbortControllers.values().forEach((controller) => {
          try {
            controller.abort()
          } catch {}
        })
        // Cleanup, because leaving this page.
        this.disconnect()
      }
    }

    // Cleanup controllers once a frame finishes loading
    this._frameLoadHandler = (event) => {
      const target = event.target
      if (target?.tagName === 'TURBO-FRAME') {
        this.frameAbortControllers.delete(target)
      }
    }

    document.addEventListener('turbo:before-fetch-request', this._beforeFetchHandler)
    document.addEventListener('turbo:before-visit', this._beforeVisitHandler)
    document.addEventListener('turbo:frame-load', this._frameLoadHandler)

    this.frameTargets.forEach((frame) => frame.removeAttribute('disabled'))
    this.initialized = true
  }

  frameTargetConnected (frame) {
    // In case there are any late arrivals.
    if (this.initialized) {
      frame.removeAttribute('disabled')
    }
  }

  disconnect () {
    // Clean up event listeners and abort any stragglers
    if (this._beforeFetchHandler) {
      document.removeEventListener('turbo:before-fetch-request', this._beforeFetchHandler)
      this._beforeFetchHandler = null
    }
    if (this._beforeVisitHandler) {
      document.removeEventListener('turbo:before-visit', this._beforeVisitHandler)
      this._beforeVisitHandler = null
    }
    if (this._frameLoadHandler) {
      document.removeEventListener('turbo:frame-load', this._frameLoadHandler)
      this._frameLoadHandler = null
    }
    if (this.frameAbortControllers) {
      this.frameAbortControllers.forEach((controller) => {
        try { controller.abort() } catch {}
      })
      this.frameAbortControllers.clear()
    }
  }
}
