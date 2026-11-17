import { Controller } from '@hotwired/stimulus'

// Expands or collapses every node of an @andypf/json-viewer, which has no built-in way to do this.
// The viewer ignores an `expanded` value equal to the last one set, even after nodes were toggled by hand,
// so the opposite value is set first to force a re-render.
export default class extends Controller {
  static targets = ['viewer']

  expandAll () {
    this.setExpanded(true)
  }

  collapseAll () {
    this.setExpanded(false)
  }

  setExpanded (expanded) {
    this.viewerTarget.expanded = !expanded
    this.viewerTarget.expanded = expanded
  }
}
