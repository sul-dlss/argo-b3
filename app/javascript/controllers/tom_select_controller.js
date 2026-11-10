import { Controller } from '@hotwired/stimulus'
import TomSelect from 'tom-select'
import MorphableTomSelect from 'controllers/morphable_tom_select'

// Connects a (multiple) select to Tom Select, loading options from a JSON endpoint on focus and as the user types.
// The endpoint receives the typed text (blank on focus) as the q param and returns a list of options,
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
    this.morphable = new MorphableTomSelect(this.element, { build: () => this.build() })
    this.morphable.connect()

    this.formChangeHandler = (event) => this.formChanged(event)
    this.element.form?.addEventListener('change', this.formChangeHandler)
  }

  build () {
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
      // A blank query loads the endpoint's default options, e.g., on focus or after clearing the typed text.
      shouldLoad: (query) => query.length === 0 || query.length >= this.minQueryLengthValue,
      load: (query, callback) => this.load(query, callback),
      // Reloads on every focus, since the default options depend on other fields (formParams).
      onFocus: () => { if (this.tomSelect.inputValue() === '') this.tomSelect.load('') }
    })
    // A caret suggests a fixed list, but the options are searched by typing.
    this.tomSelect.wrapper.classList.add('no-caret')
    return this.tomSelect
  }

  disconnect () {
    this.element.form?.removeEventListener('change', this.formChangeHandler)
    this.morphable.disconnect()
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
