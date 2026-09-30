import { Controller } from '@hotwired/stimulus'

// Retrieves the title for a catalog record id (FOLIO instance HRID) and displays it in a read-only
// field. The endpoint receives the catalog record id as the catalog_record_id param and returns
// either { "title": "..." } or { "error": "..." }.
// The field is disabled until a title has been retrieved, so that an empty one is visibly inactive
// rather than looking like a field waiting to be filled in.
export default class extends Controller {
  static targets = ['hrid', 'button', 'title', 'error', 'submissionError']
  static values = {
    url: String,
    errorMessage: String
  }

  connect () {
    this.syncDisabled()
  }

  // radio_controller enables every input inside the selected radio's container, including this one, so
  // the disabled state has to be re-asserted after it runs: on connect (Stimulus connects this
  // controller after radio_controller, which is on an ancestor) and on the events it responds to.
  // This only ever disables, so it never overrides radio_controller disabling an unselected radio's
  // fields.
  syncDisabled () {
    if (this.titleTarget.value === '') this.titleTarget.disabled = true
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
        this.showTitle(body.title)
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
    this.titleTarget.value = ''
    this.titleTarget.disabled = true
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

  showTitle (title) {
    this.titleTarget.value = title
    this.titleTarget.disabled = false
  }

  // Marking the input is what reveals the message, via Bootstrap's `.is-invalid ~ .invalid-feedback`,
  // and it gives the input the same red border a server-side error does.
  showError (message) {
    this.errorTarget.textContent = message || this.errorMessageValue
    this.hridTarget.classList.add('is-invalid')
  }
}
