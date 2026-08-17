import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static outlets = ['dropzone']

  // Called by dropzone controller after queue is complete so that files sections can be reloaded.
  reload () {
    this.element.reload()
  }
}
