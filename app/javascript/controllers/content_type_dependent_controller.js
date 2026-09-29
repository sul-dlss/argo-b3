import { Controller } from '@hotwired/stimulus'

// Enables each dependent field or fieldset only when the selected content type is one of its allowed values.
// Disabling keeps the fields out of the submitted params without changing which of them are selected,
// so a previous selection is shown again when the dependent is re-enabled.
// Mark the content type select with:
//   <select data-content-type-dependent-target="contentType" data-action="content-type-dependent#toggle"></select>
// Mark each dependent with its allowed content types:
//   <fieldset data-content-type-dependent-target="dependent" data-content-type-dependent-allowed='["..."]'></fieldset>
export default class extends Controller {
  static targets = ['contentType', 'dependent']

  connect () {
    this.toggle()
  }

  toggle () {
    const contentType = this.contentTypeTarget.value
    this.dependentTargets.forEach((dependent) => {
      const allowed = JSON.parse(dependent.dataset.contentTypeDependentAllowed)
      dependent.disabled = !allowed.includes(contentType)
    })
  }
}
