import { Controller } from '@hotwired/stimulus'

// A turbo-frame that other controllers (e.g., dropzone, frame-reloader) can reload via the reloadable-frame outlet.
export default class extends Controller {
  reload () {
    this.element.reload()
  }
}
