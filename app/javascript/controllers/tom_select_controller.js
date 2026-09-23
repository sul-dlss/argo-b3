import { Controller } from '@hotwired/stimulus'
import TomSelect from 'tom-select'

// Connects a (multiple) select to Tom Select, loading options from a JSON endpoint as the user types.
// The endpoint receives the typed text as the q param and returns a list of options,
// e.g., [{ "value": "druid:bc123df4567", "text": "My collection" }].
// The formParams value maps additional query params to the names of fields in the same form,
// e.g., { "apo_druid": "item[apo_druid]" }. When those fields change, the loaded options are cleared
// so that the next query uses the new values.
export default class extends Controller {
  static values = {
    url: String,
    valueField: { type: String, default: 'value' },
    labelField: { type: String, default: 'text' },
    placeholder: String,
    minQueryLength: { type: Number, default: 2 },
    formParams: { type: Object, default: {} }
  }

  connect () {
    this.tomSelect = new TomSelect(this.element, {
      valueField: this.valueFieldValue,
      labelField: this.labelFieldValue,
      searchField: [this.labelFieldValue],
      placeholder: this.placeholderValue,
      create: false,
      maxItems: null,
      plugins: ['remove_button'],
      clearAfterSelect: true,
      closeAfterSelect: true,
      // The endpoint determines which options match and their order, so every loaded option is shown as is.
      score: () => () => 1,
      shouldLoad: (query) => query.length >= this.minQueryLengthValue,
      load: (query, callback) => this.load(query, callback)
    })

    this.formChangeHandler = (event) => this.formChanged(event)
    this.element.form?.addEventListener('change', this.formChangeHandler)
  }

  disconnect () {
    this.element.form?.removeEventListener('change', this.formChangeHandler)
    this.tomSelect?.destroy()
  }

  formChanged (event) {
    if (!Object.values(this.formParamsValue).includes(event.target.name)) return

    // Removes the options loaded with the previous values (but not the selected options).
    this.tomSelect.clearOptions()
  }

  async load (query, callback) {
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set('q', query)
    this.setFormParams(url)
    try {
      const response = await fetch(url, { headers: { Accept: 'application/json' } })
      if (!response.ok) throw new Error(`Loading options failed: ${response.status}`)

      const options = await response.json()
      // Removes the options from previous queries (but not the selected options).
      this.tomSelect.clearOptions()
      callback(options)
    } catch (error) {
      console.error(error)
      callback()
    }
  }

  // Unchecked checkboxes and blank fields are omitted.
  setFormParams (url) {
    if (!this.element.form) return

    const formData = new FormData(this.element.form)
    Object.entries(this.formParamsValue).forEach(([param, fieldName]) => {
      const value = formData.get(fieldName)
      if (value) url.searchParams.set(param, value)
    })
  }
}
