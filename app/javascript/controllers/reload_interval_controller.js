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
    // Likewise skipped once any visit (e.g., a link click) starts, since the location changes only when it completes.
    document.addEventListener('turbo:visit', this.handleVisit)
    document.addEventListener('turbo:load', this.handleLoad)

    this.href = window.location.href
    if (this.reloadInterval) return
    this.reloadInterval = setInterval(() => {
      if (this.href !== window.location.href || this.submitting || this.visiting) return
      Turbo.visit(window.location.href, { action: 'replace' }) // eslint-disable-line no-undef
    }, this.intervalValue)
  }

  disconnect () {
    if (this.reloadInterval) clearInterval(this.reloadInterval)
    this.element.removeEventListener('turbo:submit-start', this.handleSubmitStart)
    this.element.removeEventListener('turbo:submit-end', this.handleSubmitEnd)
    document.removeEventListener('turbo:visit', this.handleVisit)
    document.removeEventListener('turbo:load', this.handleLoad)
  }

  handleVisit = () => {
    this.visiting = true
  }

  // A morph refresh keeps this element, so reloading resumes once the visit completes.
  handleLoad = () => {
    this.visiting = false
  }

  handleSubmitStart = () => {
    this.submitting = true
  }

  // Turbo ends a successful submission before visiting its response, so a reload then would cancel that visit.
  // The visit replaces this element, so only a failed submission needs to resume reloading.
  handleSubmitEnd = (event) => {
    if (!event.detail.success) this.submitting = false
  }
}
