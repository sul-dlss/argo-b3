import { Controller } from '@hotwired/stimulus'
import TomSelect from 'tom-select'
import MorphableTomSelect from 'controllers/morphable_tom_select'

// Turns a (single) select into a searchable select that also accepts values that are not among its options.
// Set data-creatable-select-dropdown-parent-value (e.g., to "body") to render the dropdown there,
// so that it is not clipped by a scrolling container such as a responsive table.
export default class extends Controller {
  static values = { dropdownParent: String }

  connect () {
    this.morphable = new MorphableTomSelect(this.element, { build: () => this.build() })
    this.morphable.connect()
  }

  build () {
    this.tomSelect = new TomSelect(this.element, {
      create: true,
      // Keeps a created value as an option, so that it can be reselected after selecting another value.
      persist: true,
      // Show every matching option rather than tom-select's default of 50.
      maxOptions: null,
      dropdownParent: this.dropdownParentValue || null
    })
    // A caret suggests a closed list of options, but any value can be entered.
    this.tomSelect.wrapper.classList.add('no-caret')
    return this.tomSelect
  }

  disconnect () {
    // Turbo caches pages, so the widget must be torn down or it is duplicated on restore.
    this.morphable.disconnect()
    this.tomSelect = null
  }
}
