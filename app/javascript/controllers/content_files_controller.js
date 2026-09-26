import { Controller } from '@hotwired/stimulus'

// Marks files of a file set (resource) for deletion. Deletion takes effect when the form is saved.
// Each row has data-content-files-target="row" and contains a hidden _destroy field
// (data-content-files-target="destroy") and a Remove button (data-action="content-files#remove").
export default class extends Controller {
  static targets = ['row', 'destroy', 'allRemovedNote']

  // Hides rows already marked for deletion, e.g., when the form is re-rendered after a failed save.
  connect () {
    this.rowTargets.forEach((row) => {
      if (this.isMarkedForDeletion(row)) this.hide(row)
    })
    this.updateAllRemovedNote()
  }

  remove (event) {
    event.preventDefault()
    const row = event.target.closest('[data-content-files-target="row"]')
    this.destroyInputFor(row).value = 'true'
    this.hide(row)
    this.updateAllRemovedNote()
  }

  // A class (rather than the hidden attribute) is used, since Bootstrap display classes (e.g., d-flex) override the hidden attribute.
  hide (row) {
    row.classList.add('d-none')
  }

  isMarkedForDeletion (row) {
    return this.destroyInputFor(row).value === 'true'
  }

  destroyInputFor (row) {
    return row.querySelector('[data-content-files-target="destroy"]')
  }

  updateAllRemovedNote () {
    const allRemoved = this.rowTargets.length > 0 && this.rowTargets.every((row) => row.classList.contains('d-none'))
    this.allRemovedNoteTarget.hidden = !allRemoved
  }
}
