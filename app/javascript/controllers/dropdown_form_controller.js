import { Controller } from '@hotwired/stimulus'
import { Dropdown } from 'bootstrap'

// A form in a Bootstrap dropdown menu, which Cancel closes without submitting.
// Cancel also resets the form, so the dropdown reopens with the values the page loaded with.
export default class extends Controller {
  static targets = ['toggle', 'form']

  cancel () {
    this.formTarget.reset()
    Dropdown.getOrCreateInstance(this.toggleTarget).hide()
    this.toggleTarget.focus()
  }
}
