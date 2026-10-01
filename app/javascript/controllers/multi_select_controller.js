import { Controller } from '@hotwired/stimulus'
import TomSelect from 'tom-select'

// Turns a <select multiple> into a searchable multi-select with removable pills.
// Attach to the field container so that the optional warning target can live alongside the select.
// Set the disabled value to disable the field; setting the select's own disabled attribute is not
// enough, because tom-select hides the select and renders its own control in a sibling element.
export default class extends Controller {
  static targets = ['select', 'warning']
  static values = { maxRecommended: Number, disabled: Boolean }

  connect () {
    this.tomSelect = new TomSelect(this.selectTarget, {
      plugins: ['remove_button'],
      // Show every matching option rather than tom-select's default of 50.
      maxOptions: null,
      // Enter already commits the highlighted option; this makes Tab do the same.
      selectOnTab: true,
      // Without this the committed query stays in the search box, so the next one appends to it.
      clearAfterSelect: true,
      onChange: () => this.toggleWarning()
    })
    this.toggleWarning()
    // Stimulus runs value callbacks before connect, when the widget does not exist yet.
    this.applyDisabled()
  }

  disconnect () {
    // Turbo caches pages, so the widget must be torn down or it is duplicated on restore.
    this.tomSelect?.destroy()
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

  // Show the warning target once more than the recommended number of options is selected.
  toggleWarning () {
    if (!this.hasWarningTarget || !this.hasMaxRecommendedValue) return

    this.warningTarget.classList.toggle('d-none', this.tomSelect.items.length <= this.maxRecommendedValue)
  }
}
