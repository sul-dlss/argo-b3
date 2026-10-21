import { Controller } from '@hotwired/stimulus'

// Disables the disableable targets while a form declaring the disable-actions actions is submitting
// (see DisableActionsHelper) or while a dropzone is uploading (dropzone:upload-start / dropzone:upload-end).
// Attach to a container that holds both the forms (or dropzone) and the targets. Note that Stimulus doesn't
// deliver events from within a nested disable-actions controller to the outer one.
// Targets are buttons, inputs, fieldsets of buttons, links, or other elements that handle
// disable-actions:disable / disable-actions:enable events (e.g., a dropzone).
export default class extends Controller {
  static targets = ['disableable']

  disable () {
    this.disabled = true
    this.disableableTargets.forEach(element => this.setDisabled(element, true))
  }

  enable () {
    this.disabled = false
    this.disableableTargets.forEach(element => this.setDisabled(element, false))
  }

  // Targets rendered while disabled (e.g., a frame reloaded while uploading) are disabled too.
  disableableTargetConnected (element) {
    if (this.disabled) this.setDisabled(element, true)
  }

  setDisabled (element, disabled) {
    // Links (<a> elements, e.g., the edit pencil) have no disabled property, so instead they get Bootstrap's
    // .disabled (which prevents clicks on .btn links), aria-disabled for screen readers, and tabindex -1 to
    // remove them from keyboard navigation. Fieldsets can be disabled, which disables all of their buttons.
    // Other elements without a disabled property (e.g., a dropzone) are sent an event so that they can
    // disable / enable themselves, e.g., data-action="disable-actions:disable->dropzone#disable".
    if (element.tagName === 'A') {
      element.classList.toggle('disabled', disabled)
      if (disabled) {
        element.setAttribute('aria-disabled', 'true')
        element.setAttribute('tabindex', '-1')
      } else {
        element.removeAttribute('aria-disabled')
        element.removeAttribute('tabindex')
      }
    } else if ('disabled' in element) {
      element.disabled = disabled
    } else {
      this.dispatch(disabled ? 'disable' : 'enable', { target: element, bubbles: false })
    }
  }
}
