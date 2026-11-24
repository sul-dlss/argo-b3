import { Controller } from '@hotwired/stimulus'

// Keeps the choice of how to structure new files (see contents/show) when the files frame reloads, e.g., after
// another upload or a delete, since the reloaded question is rendered with the default choice. The choice is
// forgotten once the question is no longer shown (e.g., the new files were deleted).
export default class extends Controller {
  static targets = ['radio']

  radioTargetConnected (radio) {
    if (this.choice && radio.value === this.choice) radio.checked = true
  }

  remember (event) {
    this.choice = event.target.value
  }

  forget () {
    if (!this.hasRadioTarget) this.choice = null
  }
}
