import { Controller } from '@hotwired/stimulus'

// Toggles a row's details when the row is clicked, via its toggle button so that aria-expanded stays correct.
export default class extends Controller {
  static targets = ['button']

  toggle (event) {
    if (this.buttonTarget.contains(event.target)) return

    this.buttonTarget.click()
  }
}
