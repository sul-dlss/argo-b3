import { Controller } from '@hotwired/stimulus'

// Enables the inputs of the dependent targets only while the checkbox target is checked, leaving them visible.
// Unchecking clears the dependent radio buttons; checking with none chosen chooses the default target.
// Mark the elements with:
//   <div data-controller="enable-when-checked">
//     <input type="checkbox" data-enable-when-checked-target="checkbox" data-action="enable-when-checked#toggle">
//     <fieldset data-enable-when-checked-target="dependent">
//       <input type="radio"><input type="radio" data-enable-when-checked-target="default">
//     </fieldset>
//   </div>
export default class extends Controller {
  static targets = ['checkbox', 'dependent', 'default']

  connect () {
    this.toggle()
  }

  toggle () {
    const checked = this.checkboxTarget.checked
    const inputs = this.dependentTargets.flatMap((dependent) => Array.from(dependent.querySelectorAll('input')))
    inputs.forEach((input) => {
      input.disabled = !checked
      if (!checked && input.type === 'radio') input.checked = false
    })
    if (checked && this.hasDefaultTarget && !inputs.some((input) => input.type === 'radio' && input.checked)) {
      this.defaultTarget.checked = true
    }
  }
}
