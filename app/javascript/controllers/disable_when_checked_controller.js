import { Controller } from '@hotwired/stimulus'
import { setFieldsAvailable } from 'controllers/dependent_fields'

// Hides and disables the dependent targets (fields' containers or fieldsets) while the checkbox target is checked,
// and shows and enables them when it is not.
// Mark the elements with:
//   <div data-controller="disable-when-checked">
//     <input type="checkbox" data-disable-when-checked-target="checkbox" data-action="disable-when-checked#toggle">
//     <div data-disable-when-checked-target="dependent"><input></div>
//   </div>
export default class extends Controller {
  static targets = ['checkbox', 'dependent']

  connect () {
    this.toggle()
  }

  toggle () {
    this.dependentTargets.forEach((dependent) => setFieldsAvailable(dependent, !this.checkboxTarget.checked))
  }
}
