import { Controller } from '@hotwired/stimulus'
import { choiceContent } from 'controllers/dependent_fields'

// Shows and enables the content of a checkbox (e.g., its inputs) only while it is checked.
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
    // Hidden as well as disabled, since disabled inputs alone were not obviously unavailable.
    choiceContent(this.element).forEach((element) => element.classList.toggle('d-none', !this.element.checked))
  }
}
