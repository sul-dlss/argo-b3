import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

const PRESERVED_CLASSES = ['nav-link', 'tab-pane', 'accordion-button', 'accordion-collapse', 'toggle-row', 'toggle-row-data']

// Controller for the Cocina model show page.
//
// The show page periodically refreshes itself with a Turbo morph refresh (see scheduleReload), which
// resets element attributes (e.g., class, aria-expanded) to what the server rendered. Interactive UI
// state that must survive the refresh (e.g., the active tab or expanded/collapsed rows) is only kept if
// the element's attributes are skipped by the turbo:before-morph-attribute hook (preserveTab): either add
// the element's class to PRESERVED_CLASSES or extend that hook.
export default class extends Controller {
  static values = {
    interval: Number
  }

  connect () {
    document.addEventListener('turbo:before-morph-attribute', this.preserveTab)
    document.addEventListener('turbo:before-morph-element', this.preserveNavigatedFrame)
    document.addEventListener('turbo:before-fetch-response', this.handleFrameResponse)
    document.addEventListener('turbo:before-frame-render', this.preventFailedFrameRender)
    document.addEventListener('turbo:frame-missing', this.handleMissingFrame)
    document.addEventListener('turbo:submit-start', this.handleSubmitStart)
    document.addEventListener('turbo:submit-end', this.handleSubmitEnd)
    document.addEventListener('turbo:before-visit', this.preventRefreshWhileSubmitting)
    document.addEventListener('turbo:before-render', this.skipRefreshRenderWhileSubmitting)

    this.href = window.location.href
    if (this.reloadTimeout) return

    this.scheduleReload()
  }

  disconnect () {
    if (this.reloadTimeout) {
      clearTimeout(this.reloadTimeout)
      this.reloadTimeout = null
    }

    document.removeEventListener('turbo:before-morph-attribute', this.preserveTab)
    document.removeEventListener('turbo:before-morph-element', this.preserveNavigatedFrame)
    document.removeEventListener('turbo:before-fetch-response', this.handleFrameResponse)
    document.removeEventListener('turbo:before-frame-render', this.preventFailedFrameRender)
    document.removeEventListener('turbo:frame-missing', this.handleMissingFrame)
    document.removeEventListener('turbo:submit-start', this.handleSubmitStart)
    document.removeEventListener('turbo:submit-end', this.handleSubmitEnd)
    document.removeEventListener('turbo:before-visit', this.preventRefreshWhileSubmitting)
    document.removeEventListener('turbo:before-render', this.skipRefreshRenderWhileSubmitting)
  }

  // This preserves the active tab when the page is refreshed
  // by preventing Turbo from morphing the tab list, tab pane, accordion button,
  // accordion body, and toggle row / data attributes
  preserveTab = (event) => {
    if (PRESERVED_CLASSES.some((className) => event.target.classList.contains(className))) {
      event.preventDefault()
    }
  }

  // A frame that has navigated (e.g., the events frame after filtering) has a different src than the frame in
  // the refreshed page. Rather than morphing it back to the original src (which loses the navigation),
  // this reloads the frame from its current src.
  // A busy frame (e.g., while a filter form submission is in flight) is left alone, since its src is not updated
  // until the response arrives; reloading it would race the submission and could restore the original src.
  preserveNavigatedFrame = (event) => {
    const { currentElement, newElement } = event.detail
    if (currentElement.tagName !== 'TURBO-FRAME' || currentElement.getAttribute('refresh') !== 'morph') return

    if (currentElement.hasAttribute('busy')) {
      event.preventDefault()
      return
    }

    const currentSrc = currentElement.getAttribute('src')
    const newSrc = newElement.getAttribute('src')
    if (!currentSrc || !newSrc || this.absoluteUrl(currentSrc) === this.absoluteUrl(newSrc)) return

    event.preventDefault()
    currentElement.reload()
  }

  absoluteUrl (url) {
    return new URL(url, window.location.href).href
  }

  // Refreshes the whole page (via Turbo's morph-based page refresh) on each interval, rather than
  // reloading each turbo frame individually. The show action refreshes the solr doc / cocina hash
  // caches only when the object's lock has changed, so this single request is what drives every
  // frame (each tagged `refresh="morph"`) to reload off of already-warm caches, without needing to
  // stagger the frame reloads to avoid bursts of requests.
  scheduleReload = () => {
    this.reloadTimeout = setTimeout(() => {
      if (this.href === window.location.href && document.visibilityState === 'visible') {
        Turbo.session.refresh(this.href)
      }

      this.scheduleReload()
    }, this.intervalValue)
  }

  // A page refresh starts a Turbo visit, which aborts any in-flight form submission (e.g., pinning or
  // republishing) so that its response (e.g., a toast) is never rendered. So the refresh is skipped while a
  // submission is in flight.
  // This is checked when the visit starts, since Turbo debounces session.refresh (by 150ms).
  preventRefreshWhileSubmitting = (event) => {
    if (this.submitting && event.detail.url === window.location.href) event.preventDefault()
  }

  // A refresh that started before a submission can still render during it. Turbo would then reload a frame whose
  // submission (e.g., the events filter) is in flight from its original src, so that render is skipped.
  skipRefreshRenderWhileSubmitting = (event) => {
    if (this.submitting && event.detail.renderMethod === 'morph') event.detail.render = () => {}
  }

  handleSubmitStart = () => {
    this.submitting = true
  }

  handleSubmitEnd = () => {
    this.submitting = false
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
