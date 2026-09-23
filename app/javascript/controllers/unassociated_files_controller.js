import { Controller } from '@hotwired/stimulus'

// Disables submit buttons (e.g., save as draft, deposit) while the content has files
// that have not been added to the structure.
// The unassociated target is rendered by the structure section, which is loaded and reloaded
// in a turbo frame. Until that frame has loaded, the target is present, so the submit buttons
// start out disabled.
export default class extends Controller {
  static targets = ['submit', 'unassociated']

  submitTargetConnected () {
    this.updateSubmitTargets()
  }

  unassociatedTargetConnected () {
    this.updateSubmitTargets()
  }

  unassociatedTargetDisconnected () {
    this.updateSubmitTargets()
  }

  updateSubmitTargets () {
    this.submitTargets.forEach((submitTarget) => { submitTarget.disabled = this.hasUnassociatedTarget })
  }
}
