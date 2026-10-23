import { Controller } from '@hotwired/stimulus'

// Reload the page on an interval
export default class extends Controller {
  static values = {
    interval: Number
  }

  connect () {
    // A reload starts a Turbo visit, which cancels an in-flight filter submission, so it is skipped while submitting.
    this.element.addEventListener('turbo:submit-start', this.handleSubmitStart)
    this.element.addEventListener('turbo:submit-end', this.handleSubmitEnd)

    this.href = window.location.href
    if (this.reloadInterval) return
    this.reloadInterval = setInterval(() => {
      if (this.href !== window.location.href || this.submitting) return
      Turbo.visit(window.location.href, { action: 'replace' }) // eslint-disable-line no-undef
    }, this.intervalValue)
  }

  disconnect () {
    if (this.reloadInterval) clearInterval(this.reloadInterval)
    this.element.removeEventListener('turbo:submit-start', this.handleSubmitStart)
    this.element.removeEventListener('turbo:submit-end', this.handleSubmitEnd)
  }

  handleSubmitStart = () => {
    this.submitting = true
  }

  handleSubmitEnd = () => {
    this.submitting = false
  }
}
