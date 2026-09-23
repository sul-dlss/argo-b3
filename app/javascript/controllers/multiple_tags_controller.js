import { Controller } from '@hotwired/stimulus'

// Distributes a tab- or newline-delimited list of tags entered in a single text area into the
// other, project, and ticket has-many sections rendered alongside it.
//   <div data-controller="multiple-tags"
//        data-multiple-tags-has-many-outlet=".tag-fields"
//        data-multiple-tags-section-labels-value='{"other_tags":"Tags", ...}'>
//     <textarea data-multiple-tags-target="input"></textarea>
//     <button data-action="multiple-tags#add">Add tags</button>
//     <div role="status" data-multiple-tags-target="status"></div>
//     ...has-many sections, each with data-has-many-field-name-value...
//   </div>
//
// Keep the prefixes in sync with ProjectTagForm::PROJECT_TAG_PREFIX and
// TicketTagForm::TICKET_TAG_PREFIX. Matching here is deliberately more lenient than the
// server-side prefix stripping, so that a tag like "project : Argo" is filed under project tags
// rather than silently landing in the other tags section.
const SECTIONS = [
  { pattern: /^project\s*:\s*/i, fieldName: 'project_tags' },
  { pattern: /^ticket\s*:\s*/i, fieldName: 'ticket_tags' },
  // Catch-all, so it must come last.
  { pattern: /^/, fieldName: 'other_tags' }
]

export default class extends Controller {
  static targets = ['input', 'status']
  static outlets = ['has-many']
  static values = { sectionLabels: Object }

  add (event) {
    event.preventDefault()

    const counts = new Map()
    this.tags.forEach((tag) => {
      const section = SECTIONS.find(({ pattern }) => pattern.test(tag))
      this.sectionFor(section.fieldName).addValue(tag.replace(section.pattern, '').trim())
      counts.set(section.fieldName, (counts.get(section.fieldName) ?? 0) + 1)
    })

    this.inputTarget.value = ''
    this.announce(counts)
  }

  get tags () {
    return this.inputTarget.value
      .split(/[\t\r\n]+/)
      .map((tag) => tag.trim())
      .filter((tag) => tag !== '')
  }

  sectionFor (fieldName) {
    return this.hasManyOutlets.find((outlet) => outlet.fieldNameValue === fieldName)
  }

  // The rows are added below the button without moving focus, so this live region is the only
  // feedback a screen reader user gets.
  announce (counts) {
    const added = SECTIONS
      .filter(({ fieldName }) => counts.has(fieldName))
      .map(({ fieldName }) => `${counts.get(fieldName)} to ${this.sectionLabelsValue[fieldName]}`)

    this.statusTarget.textContent = ''
    // An identical message is only announced again if the region is cleared first.
    window.requestAnimationFrame(() => {
      this.statusTarget.textContent = added.length === 0 ? 'No tags added.' : `Added ${added.join(', ')}.`
    })
  }
}
