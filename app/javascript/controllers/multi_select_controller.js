import { Controller } from '@hotwired/stimulus'
import TomSelect from 'tom-select'

// Turns a <select multiple> into a searchable multi-select with removable pills.
// Attach to the field container so that the optional warning target can live alongside the select.
export default class extends Controller {
  static targets = ['select', 'warning']
  static values = { maxRecommended: Number }

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
  }

  disconnect () {
    // Turbo caches pages, so the widget must be torn down or it is duplicated on restore.
    this.tomSelect?.destroy()
    this.tomSelect = null
  }

  // Show the warning target once more than the recommended number of options is selected.
  toggleWarning () {
    if (!this.hasWarningTarget || !this.hasMaxRecommendedValue) return

    this.warningTarget.classList.toggle('d-none', this.tomSelect.items.length <= this.maxRecommendedValue)
  }
}
