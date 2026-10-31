import { Controller } from '@hotwired/stimulus'
import { choiceContent } from 'controllers/dependent_fields'

// Shows and enables the content of the selected radio button (e.g., its inputs), and hides and disables
// the content of the others.
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
    this.radioTargets.forEach((radio) => this.disableInputs(radio, !radio.checked))
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
    // Hidden as well as disabled, since disabled inputs alone were not obviously unavailable.
    choiceContent(radioElem).forEach((element) => element.classList.toggle('d-none', disable))
    // Turbo frames with data-radio-src are loaded from that url the first time the radio is selected,
    // so that they aren't loaded (e.g., calling an external API) unless needed.
    if (!disable) {
      const lazyFrames = containerElem.querySelectorAll('turbo-frame[data-radio-src]:not([src])')
      lazyFrames.forEach((frame) => {
        frame.src = frame.dataset.radioSrc
      })
    }
    // Elements that have radio-disableable class are sent a radio:disable or radio:enable event
    // so that elements that aren't form inputs (e.g., a dropzone) can disable / enable themselves.
    // For example: data-action="radio:disable->dropzone#disable radio:enable->dropzone#enable"
    const disableableEls = containerElem.querySelectorAll('.radio-disableable')
    disableableEls.forEach((el) => {
      this.dispatch(disable ? 'disable' : 'enable', { target: el, bubbles: false })
    })
  }
}
