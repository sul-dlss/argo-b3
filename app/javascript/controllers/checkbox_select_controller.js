import { Controller } from '@hotwired/stimulus'

// For managing "Check all" / "Check none" links for groups of checkboxes
export default class extends Controller {
  static targets = ['checkbox']

  checkAll (event) {
    event.preventDefault()
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = true
      checkbox.dispatchEvent(new Event('change', { bubbles: true }))
    })
  }

  checkNone (event) {
    event.preventDefault()
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = false
      checkbox.dispatchEvent(new Event('change', { bubbles: true }))
    })
  }
}
