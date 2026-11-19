import { Controller } from '@hotwired/stimulus'
import { Dropdown } from 'bootstrap'

// A form in a Bootstrap dropdown menu, which Cancel closes without submitting.
// Cancel also resets the form, so the dropdown reopens with the values the page loaded with.
// While the dropdown is open, a page refresh (e.g., the object page's periodic morph) leaves it alone, so that it
// stays open and keeps what the user has typed. Submitting closes it, so that the page the submission returns to
// is rendered in full.
export default class extends Controller {
  static targets = ['toggle', 'form']

  connect () {
    this.element.addEventListener('turbo:before-morph-element', this.preserveWhileOpen)
  }

  disconnect () {
    this.element.removeEventListener('turbo:before-morph-element', this.preserveWhileOpen)
  }

  cancel () {
    this.formTarget.reset()
    this.close()
    this.toggleTarget.focus()
  }

  close () {
    Dropdown.getOrCreateInstance(this.toggleTarget).hide()
  }

  preserveWhileOpen = (event) => {
    if (event.target === this.element && this.toggleTarget.getAttribute('aria-expanded') === 'true') {
      event.preventDefault()
    }
  }
}
