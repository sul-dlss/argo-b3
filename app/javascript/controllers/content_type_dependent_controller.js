import { Controller } from '@hotwired/stimulus'

// Enables a dependent fieldset only when the selected content type is one of the allowed values.
// Disabling the fieldset keeps its fields out of the submitted params without changing which of them
// are checked, so a previous selection is shown again when the fieldset is re-enabled.
// Mark the content type select with:
//   <select data-content-type-dependent-target="contentType" data-action="content-type-dependent#toggle"></select>
// Mark the dependent fieldset with:
//   <fieldset data-content-type-dependent-target="dependent"></fieldset>
export default class extends Controller {
  static targets = ['contentType', 'dependent']
  static values = { allowed: Array }

  connect () {
    this.toggle()
  }

  toggle () {
    this.dependentTarget.disabled = !this.allowedValue.includes(this.contentTypeTarget.value)
  }
}
