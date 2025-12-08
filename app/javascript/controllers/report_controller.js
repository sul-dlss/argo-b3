import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  updateSubmit () {
    const noneChecked = this.element.querySelectorAll('input[type="checkbox"]:checked').length === 0
    this.element.querySelectorAll('input[type="submit"]').forEach((submit) => {
      submit.disabled = noneChecked
    })
  }
}
