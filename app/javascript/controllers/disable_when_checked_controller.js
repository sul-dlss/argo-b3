import { Controller } from '@hotwired/stimulus'

// Disables the input targets while the checkbox target is checked, and enables them when it is not.
// Mark the elements with:
//   <div data-controller="disable-when-checked">
//     <input type="checkbox" data-disable-when-checked-target="checkbox" data-action="disable-when-checked#toggle">
//     <input data-disable-when-checked-target="input">
//   </div>
export default class extends Controller {
  static targets = ['checkbox', 'input']

  connect () {
    this.toggle()
  }

  toggle () {
    this.inputTargets.forEach((input) => { input.disabled = this.checkboxTarget.checked })
  }
}
