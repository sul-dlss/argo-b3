import { Controller } from '@hotwired/stimulus'

// Retrieves the title for a catalog record id (FOLIO instance HRID) and displays it as plain text.
// The endpoint receives the catalog record id as the catalog_record_id param and returns either
// { "title": "..." } or { "error": "..." }.
// The title is shown only to confirm that the catalog record id is the intended one: it is not a
// form field, so it is not submitted and the description is still refreshed from the catalog.
export default class extends Controller {
  static targets = ['hrid', 'button', 'title', 'titleContainer', 'error']
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
    this.titleContainerTarget.classList.add('d-none')
    this.errorTarget.textContent = ''
    this.errorTarget.classList.add('d-none')
    this.clearSubmissionError()
  }

  // Clears the validation error reported for this field by a previous submission of the form, so that it
  // is not shown alongside the outcome of the lookup. The sdr-tab-error controller does the clearing in
  // response to a change event, which it has not yet seen if the field was not edited before retrieving.
  clearSubmissionError () {
    if (!this.hridTarget.classList.contains('is-invalid')) return

    this.hridTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }

  showTitle (title) {
    this.titleTarget.value = title
    this.titleContainerTarget.classList.remove('d-none')
  }

  showError (message) {
    this.errorTarget.textContent = message || this.errorMessageValue
    this.errorTarget.classList.remove('d-none')
  }
}
