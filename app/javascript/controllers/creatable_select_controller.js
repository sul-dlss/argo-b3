import { Controller } from '@hotwired/stimulus'
import TomSelect from 'tom-select'
import MorphableTomSelect from 'controllers/morphable_tom_select'

// Turns a (single) select into a searchable select that also accepts values that are not among its options.
// Set the dropdownInBody value when the select is in a scroll container (e.g., a responsive table), which would
// otherwise clip the dropdown.
export default class extends Controller {
  static values = { dropdownInBody: Boolean }

  connect () {
    this.morphable = new MorphableTomSelect(this.element, { build: () => this.build() })
    this.morphable.connect()
    if (this.dropdownInBodyValue) document.addEventListener('scroll', this.reposition, { capture: true, passive: true })
  }

  build () {
    this.tomSelect = new TomSelect(this.element, {
      create: true,
      // Keeps a created value as an option, so that it can be reselected after selecting another value.
      persist: true,
      // Show every matching option rather than tom-select's default of 50.
      maxOptions: null,
      dropdownParent: this.dropdownInBodyValue ? 'body' : null
    })
    // A caret suggests a closed list of options, but any value can be entered.
    this.tomSelect.wrapper.classList.add('no-caret')
    // Tom Select handles enter first (choosing or creating a value), so enter never submits the form.
    this.tomSelect.control_input.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') event.preventDefault()
    })
    if (this.dropdownInBodyValue) this.widenDropdown()
    return this.tomSelect
  }

  // Tom Select sizes a dropdown in the body to the field, so options wider than the field would wrap.
  widenDropdown () {
    const positionDropdown = this.tomSelect.positionDropdown.bind(this.tomSelect)
    this.tomSelect.positionDropdown = () => {
      positionDropdown()
      const { style } = this.tomSelect.dropdown
      style.minWidth = style.width
      style.width = 'max-content'
    }
  }

  // Tom Select follows window scrolls only, so the dropdown would stay put when the table scrolls.
  reposition = () => {
    if (this.tomSelect?.isOpen) this.tomSelect.positionDropdown()
  }

  disconnect () {
    document.removeEventListener('scroll', this.reposition, { capture: true })
    // Turbo caches pages, so the widget must be torn down or it is duplicated on restore.
    this.morphable.disconnect()
    this.tomSelect = null
  }
}
