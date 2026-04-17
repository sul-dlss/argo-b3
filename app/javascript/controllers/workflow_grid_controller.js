import { Controller } from '@hotwired/stimulus'

// Reload the turbo-frame on the configured interval.
export default class extends Controller {
  static values = {
    interval: Number
  }

  connect () {
    if (this.element.tagName !== 'TURBO-FRAME') return

    this.element.addEventListener('turbo:before-fetch-response', this.handleFrameResponse)
    this.element.addEventListener('turbo:before-frame-render', this.preventFailedFrameRender)
    this.element.addEventListener('turbo:frame-missing', this.handleMissingFrame)
  }

  start () {
    if (this.reloadInterval) return
    // If the element is empty, no need to refresh it.
    if (this.element.innerHTML.trim() === '') return
    this.reloadInterval = setInterval(() => {
      this.element.reload()
    }, this.intervalValue)
  }

  stop () {
    if (this.reloadInterval) {
      clearInterval(this.reloadInterval)
      this.reloadInterval = null
    }
  }

  disconnect () {
    this.stop()

    if (this.element.tagName !== 'TURBO-FRAME') return

    this.element.removeEventListener('turbo:before-fetch-response', this.handleFrameResponse)
    this.element.removeEventListener('turbo:before-frame-render', this.preventFailedFrameRender)
    this.element.removeEventListener('turbo:frame-missing', this.handleMissingFrame)
  }

  // handleFrameResponse, preventFailedFrameRender, and handleMissingFrame work together to prevent
  // Turbo from rendering an error page in a frame when the server returns an error response.
  handleFrameResponse = (event) => {
    const { fetchResponse } = event.detail

    if (fetchResponse.serverError) {
      this.stop()
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
    if (event.detail.response.status >= 500) {
      this.stop()
      event.preventDefault()
    }
  }
}
