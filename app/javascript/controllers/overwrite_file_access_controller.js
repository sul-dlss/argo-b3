import { Controller } from '@hotwired/stimulus'

// Checks and disables the overwrite file access checkbox while the view access is dark,
// since the files of a dark object are always made dark.
// Registered after the toggle controller, so that the hidden section's view select is already disabled.
export default class extends Controller {
  static targets = ['checkbox']

  connect () {
    this.update()
  }

  update () {
    if (!this.hasCheckboxTarget) return

    const dark = this.element.querySelector('select[name$="[access_view]"]:enabled')?.value === 'dark'
    if (dark) this.checkboxTarget.checked = true
    // Includes the checkbox's hidden field, so that a disabled checkbox is not submitted as unchecked.
    this.element.querySelectorAll(`input[name="${this.checkboxTarget.name}"]`).forEach((input) => {
      input.disabled = dark
    })
  }
}
