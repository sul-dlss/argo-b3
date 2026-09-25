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
//
// Set has_many_field_name_value to the association name so that sibling controllers can tell
// several has-many sections apart. multiple_tags_controller calls addValue() to populate
// the various tag sections.
export default class extends Controller {
  static targets = ['container', 'row', 'template']
  static values = { fieldName: String }

  add (event) {
    event.preventDefault()
    this.appendRow()
  }

  remove (event) {
    event.preventDefault()
    event.target.closest('.form-instance').remove()
    // Never leave the user with no fields at all (if a template is provided).
    if (this.rowTargets.length === 0 && this.hasTemplateTarget) this.appendRow()
  }

  // Fills the first blank row with value, or appends a new row if every row is already filled.
  // Blank rows are filled in DOM order, so a value can land above an already-filled row.
  addValue (value) {
    const input = this.blankInput ?? this.inputFor(this.appendRow())
    input.value = value
    input.dispatchEvent(new Event('input', { bubbles: true }))
  }

  get blankInput () {
    return this.rowTargets
      .map((row) => this.inputFor(row))
      .find((input) => input.value.trim() === '')
  }

  inputFor (row) {
    return row.querySelector('input:not([type="hidden"]), textarea, select')
  }

  appendRow () {
    const row = this.templateTarget.content.cloneNode(true).firstElementChild
    this.reindex(row, this.nextIndex)
    this.containerTarget.appendChild(row)
    return row
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
