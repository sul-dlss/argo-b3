import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['sourceRadio', 'druidListInput']

  connect () {
    this.updateSubmit()
  }

  updateSubmit () {
    const noneChecked = this.element.querySelectorAll('input[type="checkbox"]:checked').length === 0
    const noDruids = this.druidListInputTarget.value.trim() === '' && this.sourceRadioTarget.checked
    // Matches both <input type="submit"> and the <button type="submit"> rendered by SubmitComponent.
    this.element.querySelectorAll('[type="submit"]').forEach((submit) => {
      submit.disabled = noneChecked || noDruids
    })
  }
}
