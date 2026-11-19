import { Controller } from '@hotwired/stimulus'
import TomSelect from 'tom-select'
import MorphableTomSelect from 'controllers/morphable_tom_select'

// Turns a (single) select into a searchable select over its own options, e.g., the APO select.
// The select keeps its options (including their data attributes) and its value in sync, and Tom Select
// dispatches change on it, so other controllers that read or listen to the select (e.g., apo-defaults) still work.
export default class extends Controller {
  connect () {
    this.morphable = new MorphableTomSelect(this.element, { build: () => this.build() })
    this.morphable.connect()
  }

  build () {
    this.tomSelect = new TomSelect(this.element, {
      create: false,
      // Otherwise the dropdown stays open after choosing, and the next click on the field closes it.
      closeAfterSelect: true,
      // Show every matching option rather than tom-select's default of 50.
      maxOptions: null
    })
    this.copyAriaToControl()
    return this.tomSelect
  }

  // The label points at Tom Select's input, which does not get the select's ARIA attributes, so that a required
  // or invalid APO (and its error message) would otherwise not be announced.
  copyAriaToControl () {
    ['aria-required', 'aria-invalid', 'aria-describedby'].forEach((attribute) => {
      const value = this.element.getAttribute(attribute)
      if (value !== null) this.tomSelect.control_input.setAttribute(attribute, value)
    })
  }

  disconnect () {
    // Turbo caches pages, so the widget must be torn down or it is duplicated on restore.
    this.morphable.disconnect()
    this.tomSelect = null
  }
}
