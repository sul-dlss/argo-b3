import { Controller } from '@hotwired/stimulus'

// Adds and removes nested form rows for a has_many association.
// Mark the wrapping element with:
//   <div data-controller="has-many">
//     <div data-has-many-target="container">
//       <template data-has-many-target="template">...one row, indexed "NEW_RECORD"...</template>
//       ...rendered rows, each with data-has-many-target="row" and data-index="N"...
//     </div>
//     <button data-action="has-many#add">Add</button>
//   </div>
// Each row's Remove button is marked with data-action="has-many#remove".
export default class extends Controller {
  static targets = ['container', 'row', 'template']

  add (event) {
    event.preventDefault()
    this.appendRow()
  }

  remove (event) {
    event.preventDefault()
    event.target.closest('.form-instance').remove()
    // Never leave the user with no fields at all.
    if (this.rowTargets.length === 0) this.appendRow()
  }

  appendRow () {
    const row = this.templateTarget.content.cloneNode(true).firstElementChild
    this.reindex(row, this.nextIndex)
    this.containerTarget.appendChild(row)
  }

  get nextIndex () {
    return Math.max(-1, ...this.rowTargets.map((row) => parseInt(row.dataset.index, 10))) + 1
  }

  // Rewrites the "NEW_RECORD" placeholder in each cloned field's name/id/for attribute to the
  // new row's index. Only these specific attributes are touched, so a field value that happens
  // to contain the literal string "NEW_RECORD" is left alone.
  reindex (row, index) {
    row.dataset.index = index
    row.querySelectorAll('[name], [id], [for]').forEach((element) => {
      ;['name', 'id', 'for'].forEach((attribute) => {
        if (element.hasAttribute(attribute)) {
          element.setAttribute(attribute, element.getAttribute(attribute).replaceAll('NEW_RECORD', index))
        }
      })
    })
  }
}
