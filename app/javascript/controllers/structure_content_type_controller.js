import { Controller } from '@hotwired/stimulus'

// Reloads the structure frame for the selected content type, so that it uses the populator for that
// content type before the content type is saved.
export default class extends Controller {
  static targets = ['frame']

  update (event) {
    const url = new URL(this.frameTarget.src, window.location.origin)
    url.searchParams.set('content_type', event.target.value)
    this.frameTarget.src = url.toString()
  }
}
