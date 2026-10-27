import { Controller } from '@hotwired/stimulus'
import TomSelect from 'tom-select'
import MorphableTomSelect from 'controllers/morphable_tom_select'

// Turns a <select multiple> into a searchable multi-select with removable pills.
// Set the disabled value to disable the field; setting the select's own disabled attribute is not
// enough, because tom-select hides the select and renders its own control in a sibling element.
export default class extends Controller {
  static targets = ['select']
  static values = { disabled: Boolean }

  connect () {
    this.morphable = new MorphableTomSelect(this.selectTarget, { build: () => this.build() })
    this.morphable.connect()
  }

  build () {
    this.tomSelect = new TomSelect(this.selectTarget, {
      plugins: ['remove_button'],
      // Show every matching option rather than tom-select's default of 50.
      maxOptions: null,
      // Without this the committed query stays in the search box, so the next one appends to it.
      clearAfterSelect: true
    })
    // Stimulus runs value callbacks before connect, when the widget does not exist yet.
    this.applyDisabled()
    return this.tomSelect
  }

  disconnect () {
    // Turbo caches pages, so the widget must be torn down or it is duplicated on restore.
    this.morphable.disconnect()
    this.tomSelect = null
  }

  disabledValueChanged () {
    this.applyDisabled()
  }

  // tom-select keeps the select's disabled attribute, its search input and the remove buttons in
  // sync, so this disables both the widget and the submitted value.
  applyDisabled () {
    if (!this.tomSelect) return

    if (this.disabledValue) {
      this.tomSelect.disable()
    } else {
      this.tomSelect.enable()
    }
  }
}
