import { Controller } from '@hotwired/stimulus'

// Retrieves the title for a catalog record id (FOLIO instance HRID) and displays it as text.
// The endpoint receives the catalog record id as the catalog_record_id param and returns
// either { "title": "..." } or { "error": "..." }.
// The title is also kept in a hidden field (the title target) so that it survives a submission that
// fails validation. The title's row is hidden until it is retrieved.
export default class extends Controller {
  static targets = ['hrid', 'button', 'title', 'titleText', 'titleRow', 'error', 'submissionError']
  static values = {
    url: String,
    errorMessage: String
  }

  async retrieve () {
    this.reset()
    const catalogRecordId = this.hridTarget.value.trim()
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set('catalog_record_id', catalogRecordId)

    this.buttonTarget.disabled = true
    try {
      const response = await fetch(url, { headers: { Accept: 'application/json' } })
      const body = await response.json()
      if (response.ok) {
        this.setTitle(body.title || '')
      } else {
        this.showError(body.error)
      }
    } catch (error) {
      console.error(error)
      this.showError(this.errorMessageValue)
    } finally {
      this.buttonTarget.disabled = false
    }
  }

  // Clears a previously retrieved title or error, e.g., when the catalog record id is changed,
  // so that a title is never shown for a catalog record id other than the one it was retrieved for.
  reset () {
    this.setTitle('')
    this.errorTarget.textContent = ''
    // Before un-marking the input: sdr-tab-error ignores a change event from a field that is not
    // currently marked invalid.
    this.clearSubmissionError()
    this.hridTarget.classList.remove('is-invalid')
  }

  // Clears the validation error reported for this field by a previous submission of the form, so that it
  // is not shown alongside the outcome of the lookup. The sdr-tab-error controller removes the message
  // and clears the tab in response to a change event, which it has not yet seen if the field was not
  // edited before retrieving. That message is rendered with an explicit d-block, so it does not hide
  // itself when the input stops being marked invalid.
  clearSubmissionError () {
    if (!this.hasSubmissionErrorTarget) return

    this.hridTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }

  setTitle (title) {
    this.titleTarget.value = title
    this.titleTextTarget.textContent = title
    this.titleRowTarget.hidden = title === ''
  }

  // Marking the input is what reveals the message, via Bootstrap's `.is-invalid ~ .invalid-feedback`,
  // and it gives the input the same red border a server-side error does.
  showError (message) {
    this.errorTarget.textContent = message || this.errorMessageValue
    this.hridTarget.classList.add('is-invalid')
  }
}
