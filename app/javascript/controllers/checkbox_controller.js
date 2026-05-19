import { Controller } from '@hotwired/stimulus'

// Disable/enable associated inputs based on checkbox selection
export default class extends Controller {
  connect () {
    this.toggle()
  }

  toggle () {
    const containerElem = this.element.closest('.form-check')
    const inputs = containerElem.querySelectorAll('input, select, textarea')
    inputs.forEach((input) => {
      if (this.element !== input) {
        input.disabled = !this.element.checked
      }
    })
  }
}
