import { Controller } from '@hotwired/stimulus'

// Disable/enable associated inputs and buttons based on radio button selection
// Borrowed from H3.
// Mark the radio buttons with: <input data-radio-target="radio" data-action="radio#toggle" type="radio" ></input>
// If inputs are loaded later (e.g., in a turbo-frame), add data-action="turbo:frame-load->radio#refresh"
// to the controller element so that the inputs are disabled/enabled once loaded.
export default class extends Controller {
  static targets = ['radio']
  connect () {
    this.refresh()
  }

  refresh () {
    this.radioTargets.forEach((radio) => {
      if (radio.checked) {
        this.toggle({ target: radio })
      }
    })
  }

  toggle (event) {
    const radioElem = event.target
    this.disableInputs(radioElem, false)
    this.radioTargets.forEach((radio) => {
      if (radio !== radioElem) {
        this.disableInputs(radio, true)
      }
    })
  }

  disableInputs (radioElem, disable) {
    const containerElem = radioElem.closest('.form-check')
    const inputs = containerElem.querySelectorAll('input, select, textarea')
    inputs.forEach((input) => {
      if (!this.radioTargets.includes(input)) {
        input.disabled = disable
      }
      // If not disabled, an element is marked required because it must go with
      // the selected radio button.
      input.setAttribute('aria-required', !disable)
    })
    // Buttons are disabled so that, for example, rows cannot be added or removed
    // for a radio button that is not selected.
    const buttons = containerElem.querySelectorAll('button')
    buttons.forEach((button) => {
      button.disabled = disable
    })
    // Elements that have radio-hide class will be hidden when the radio is not selected.
    const hideEls = containerElem.querySelectorAll('.radio-hide')
    hideEls.forEach((el) => {
      el.classList.toggle('d-none', disable)
    })
    // Elements that have radio-show class will be shown when the radio is not selected.
    const showEls = containerElem.querySelectorAll('.radio-show')
    showEls.forEach((el) => {
      el.classList.toggle('d-none', !disable)
    })
  }
}
