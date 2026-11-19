import { Controller } from '@hotwired/stimulus'

// Keeps the report form's submit buttons and preview in step with its inputs.
//
// The preview refreshes whenever a field, the source, or the druid list (on change, not while
// typing) changes. Refreshes are debounced so that a burst of changes (rapid clicking, or "Select all", which sends a change event
// per checkbox) sends one request, and a request still in flight is aborted when a newer one starts,
// so a stale response never replaces a newer one.
export default class extends Controller {
  static targets = ['sourceRadio', 'druidListInput', 'preview', 'status', 'loadingTemplate', 'errorTemplate']
  static values = { previewUrl: String, debounce: { type: Number, default: 300 } }

  connect () {
    this.updateSubmit()
    // A Turbo cache snapshot is replaced by the real page, which refreshes the preview itself.
    if (document.documentElement.hasAttribute('data-turbo-preview')) return

    // Announcing the preview loaded with the page would only be noise.
    this.refreshPreview({ announce: false })
  }

  disconnect () {
    this.cancelPreview()
  }

  // Called when an input changes.
  update () {
    this.updateSubmit()
    this.cancelPreview()
    if (!this.valid()) {
      this.clearPreview()
      return
    }
    this.debounceTimeout = setTimeout(() => this.refreshPreview(), this.debounceValue)
  }

  updateSubmit () {
    // Matches both <input type="submit"> and the <button type="submit"> rendered by SubmitComponent.
    this.element.querySelectorAll('[type="submit"]').forEach((submit) => {
      submit.disabled = !this.valid()
    })
  }

  valid () {
    const noneChecked = this.element.querySelectorAll('input[type="checkbox"]:checked').length === 0
    const noDruids = this.druidListInputTarget.value.trim() === '' && this.sourceRadioTarget.checked
    return !noneChecked && !noDruids
  }

  cancelPreview () {
    clearTimeout(this.debounceTimeout)
    this.abortController?.abort()
  }

  async refreshPreview ({ announce = true } = {}) {
    this.cancelPreview()
    if (!this.valid()) {
      this.clearPreview()
      return
    }

    const abortController = new AbortController()
    this.abortController = abortController
    this.showTemplate(this.loadingTemplateTarget)
    // Silences the spinner's own status region, so only the status target announces.
    this.previewTarget.setAttribute('aria-busy', 'true')

    try {
      const response = await fetch(this.previewUrlValue, {
        method: 'POST',
        body: new FormData(this.element.querySelector('form')),
        headers: {
          Accept: 'text/html',
          'Turbo-Frame': this.previewTarget.id,
          // The form's own authenticity token is for its action (download), not for preview.
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        signal: abortController.signal
      })
      if (!response.ok) throw new Error(`Preview failed: ${response.status}`)

      const html = await response.text()
      if (abortController.signal.aborted) return

      const frame = new window.DOMParser().parseFromString(html, 'text/html').getElementById(this.previewTarget.id)
      // E.g., redirected to sign in after the session expired.
      if (!frame) throw new Error('Preview response has no preview frame')

      this.previewTarget.removeAttribute('aria-busy')
      this.previewTarget.replaceChildren(...frame.childNodes)
      if (announce) this.statusTarget.textContent = 'Preview updated.'
    } catch (error) {
      if (abortController.signal.aborted) return

      console.error(error)
      this.previewTarget.removeAttribute('aria-busy')
      this.showTemplate(this.errorTemplateTarget)
    }
  }

  clearPreview () {
    this.previewTarget.removeAttribute('aria-busy')
    this.previewTarget.replaceChildren()
    this.statusTarget.textContent = 'Preview cleared.'
  }

  showTemplate (template) {
    this.statusTarget.textContent = ''
    this.previewTarget.replaceChildren(template.content.cloneNode(true))
  }
}
