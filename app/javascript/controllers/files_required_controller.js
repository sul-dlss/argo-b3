import { Controller } from '@hotwired/stimulus'

// Disables the submit buttons that proceed from adding files (e.g., Next) until the content has files, showing the
// reason targets while disabled.
// The file target is rendered by the files section, which is loaded and reloaded in a turbo frame (e.g., after
// uploading), so the submit buttons start out disabled until that frame has loaded.
export default class extends Controller {
  static targets = ['submit', 'file', 'reason']

  submitTargetConnected () {
    this.update()
  }

  fileTargetConnected () {
    this.update()
  }

  fileTargetDisconnected () {
    this.update()
  }

  update () {
    this.submitTargets.forEach((submitTarget) => { submitTarget.disabled = !this.hasFileTarget })
    this.reasonTargets.forEach((reasonTarget) => { reasonTarget.hidden = this.hasFileTarget })
  }
}
