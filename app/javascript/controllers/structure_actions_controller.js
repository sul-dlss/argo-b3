import { Controller } from '@hotwired/stimulus'

// Disables the resources' actions (e.g., while structuring files).
// Targets are fieldsets of buttons or links.
export default class extends Controller {
  static targets = ['disableable']

  disable () {
    this.disableableTargets.forEach(element => this.setDisabled(element, true))
  }

  enable () {
    this.disableableTargets.forEach(element => this.setDisabled(element, false))
  }

  setDisabled (element, disabled) {
    // Links (<a> elements, e.g., the edit pencil) have no disabled property, so instead they get Bootstrap's
    // .disabled (which prevents clicks on .btn links), aria-disabled for screen readers, and tabindex -1 to
    // remove them from keyboard navigation. Fieldsets can be disabled, which disables all of their buttons.
    if (element.tagName === 'A') {
      element.classList.toggle('disabled', disabled)
      if (disabled) {
        element.setAttribute('aria-disabled', 'true')
        element.setAttribute('tabindex', '-1')
      } else {
        element.removeAttribute('aria-disabled')
        element.removeAttribute('tabindex')
      }
    } else {
      element.disabled = disabled
    }
  }
}
