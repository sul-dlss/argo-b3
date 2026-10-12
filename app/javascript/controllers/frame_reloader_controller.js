import { Controller } from '@hotwired/stimulus'

// Reload the reloadable-frame outlets when connected, e.g., after files have been discovered on a mount.
export default class extends Controller {
  static outlets = ['reloadable-frame']

  reloadableFrameOutletConnected (reloadableFrame) {
    reloadableFrame.reload()
  }
}
