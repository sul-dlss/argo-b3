import { Controller } from '@hotwired/stimulus'
import TomSelect from 'tom-select'
import MorphableTomSelect from 'controllers/morphable_tom_select'

const MIN_QUERY_LENGTH = 3
// Keys that don't change the text of a tag, so they don't move an entered tag into the text box to be edited.
const NON_EDITING_KEYS = ['Tab', 'Enter', 'Escape', 'ArrowUp', 'ArrowDown', 'Shift', 'Control', 'Alt', 'Meta', 'CapsLock']

// Connects a tag text input to Tom Select, suggesting existing tags from a JSON endpoint as the user types
// while still allowing the user to enter their own tag.
//   <input type="text" name="item[project_tags_attributes][0][tag]"
//          data-controller="tag-select"
//          data-tag-select-url-path-value="/tag_suggestions?type=project"
//          data-action="input->tag-select#sync">
// The endpoint receives the typed text as the q param and returns a list of options,
// e.g., [{ "value": "Argo : Phase 1", "text": "Argo : Phase 1" }].
export default class extends Controller {
  static values = { urlPath: String }

  connect () {
    this.morphable = new MorphableTomSelect(this.element, { build: () => this.build() })
    this.morphable.connect()
  }

  build () {
    this.tomSelect = new TomSelect(this.element, {
      maxItems: 1,
      create: true,
      // Makes the typed text (rather than the first suggestion) the option chosen by enter or tab.
      addPrecedence: true,
      persist: false,
      selectOnTab: true,
      closeAfterSelect: true,
      // Tags may contain commas, so the value of the input is never split into multiple tags.
      delimiter: '\u0000',
      // The endpoint determines which options match and their order, so every loaded option is shown as is.
      score: () => () => 1,
      shouldLoad: (query) => query.length >= MIN_QUERY_LENGTH,
      load: (query, callback) => this.load(query, callback)
    })
    this.editedTag = null
    this.awaitingTyping = false
    this.preventReopeningWhenFull()
    this.keepTagEditable()
    return this.tomSelect
  }

  // Throttled refreshes and slow loads would otherwise reopen the dropdown over the next field after a tag is entered.
  // Likewise, the dropdown stays closed when a tag is moved into the text box to be edited, until the user types.
  preventReopeningWhenFull () {
    const open = this.tomSelect.open.bind(this.tomSelect)
    this.tomSelect.open = () => {
      if (this.tomSelect.isFull() && this.tomSelect.inputValue() === '') return
      if (this.awaitingTyping) return
      open()
    }
  }

  // Tom Select turns an entered tag into an item, which can only be deleted as a whole. So the tag is moved back into
  // the text box to be edited when the field is focused, or when the user starts editing a tag entered while the field
  // has focus (e.g., a picked suggestion). The input keeps the tag until it is entered again or the field is left.
  keepTagEditable () {
    const { control } = this.tomSelect
    this.tomSelect.on('focus', () => this.editTag())
    // Wraps onBlur rather than listening for blur, since Tom Select empties the text box before it dispatches blur.
    const onBlur = this.tomSelect.onBlur.bind(this.tomSelect)
    this.tomSelect.onBlur = (event) => {
      // Tom Select ignores blurs while the document lacks focus.
      if (document.hasFocus() && this.tomSelect.isFocused) this.leave()
      onBlur(event)
    }
    // Captured, so these run before Tom Select's own handlers on its text box.
    control.addEventListener('keydown', (event) => this.keydown(event), true)
    control.addEventListener('input', () => { this.awaitingTyping = false }, true)
  }

  keydown (event) {
    if (!NON_EDITING_KEYS.includes(event.key)) this.editTag()
  }

  editTag () {
    const tag = this.tomSelect.getValue()
    if (tag === '') return

    this.editedTag = tag
    this.awaitingTyping = true
    this.tomSelect.setActiveItem()
    // Removes the item along with its option, so the tag isn't offered as a stale suggestion (e.g., once the text is
    // cleared). Silently, so no events are dispatched; the input keeps the tag until it is entered again or left.
    this.tomSelect.removeOption(tag, true)
    this.tomSelect.clearActiveOption()
    this.element.value = tag
    this.tomSelect.setTextboxValue(tag)
    this.tomSelect.control_input.setSelectionRange(tag.length, tag.length)
  }

  // Replaces Tom Select's createOnBlur, so that leaving an unchanged tag doesn't dispatch change events.
  leave () {
    const { editedTag } = this
    this.editedTag = null
    this.awaitingTyping = false
    if (this.tomSelect.items.length > 0) return

    const text = this.tomSelect.inputValue()
    if (text === '') {
      this.clearInput()
    } else if (text === editedTag) {
      this.tomSelect.addOption({ value: text, text })
      this.tomSelect.addItem(text, true)
    } else {
      this.tomSelect.createItem(text)
    }
  }

  clearInput () {
    if (this.element.value !== '') this.tomSelect.updateOriginalInput()
  }

  disconnect () {
    this.morphable.disconnect()
  }

  // Updates Tom Select when the value of the input is set by other code (e.g., has-many#addValue).
  // Tom Select also dispatches input events when the user changes the value, in which case the values already match.
  sync () {
    if (this.element.value !== this.tomSelect.getValue()) this.tomSelect.sync()
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
