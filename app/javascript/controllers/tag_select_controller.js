import { Controller } from '@hotwired/stimulus'
import TomSelect from 'tom-select'

// Connects a tag text input to Tom Select, suggesting existing tags from a JSON endpoint as the user types
// while still allowing the user to enter their own tag.
//   <input type="text" name="item[project_tags_attributes][0][tag]"
//          data-controller="tag-select"
//          data-tag-select-url-path-value="/tag_suggestions?type=project"
//          data-action="input->tag-select#sync">
// The endpoint receives the typed text as the q param and returns a list of options,
// e.g., [{ "value": "Argo : Phase 1", "text": "Argo : Phase 1" }].
export default class extends Controller {
  static values = {
    urlPath: String,
    minQueryLength: { type: Number, default: 3 }
  }

  connect () {
    this.tomSelect = new TomSelect(this.element, {
      maxItems: 1,
      create: true,
      // Keeps the typed text when the user leaves the field without choosing an option.
      createOnBlur: true,
      // Makes the typed text (rather than the first suggestion) the option chosen by enter or tab.
      addPrecedence: true,
      persist: false,
      selectOnTab: true,
      // Tags may contain commas, so the value of the input is never split into multiple tags.
      delimiter: '\u0000',
      // The endpoint determines which options match and their order, so every loaded option is shown as is.
      score: () => () => 1,
      shouldLoad: (query) => query.length >= this.minQueryLengthValue,
      load: (query, callback) => this.load(query, callback)
    })
  }

  disconnect () {
    this.tomSelect?.destroy()
  }

  // Updates Tom Select when the value of the input is set by other code (e.g., has-many#addValue).
  // Tom Select also dispatches input events when the user changes the value, in which case the values already match.
  sync () {
    if (this.tomSelect && this.element.value !== this.tomSelect.getValue()) this.tomSelect.sync()
  }

  async load (query, callback) {
    const url = new URL(this.urlPathValue, window.location.origin)
    url.searchParams.set('q', query)
    try {
      const response = await fetch(url, { headers: { Accept: 'application/json' } })
      if (!response.ok) throw new Error(`Loading tag suggestions failed: ${response.status}`)

      const options = await response.json()
      // Removes the options from previous queries (but not the selected option).
      this.tomSelect.clearOptions()
      callback(options)
    } catch (error) {
      console.error(error)
      callback()
    }
  }
}
