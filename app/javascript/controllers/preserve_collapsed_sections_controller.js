import { Controller } from '@hotwired/stimulus'
import { isCollapsibleSectionState } from 'controllers/collapsible_section_morph'

// Keeps collapsible sections expanded or collapsed when Turbo morphs the page,
// which would otherwise reset them to the state the server rendered.
export default class extends Controller {
  connect () {
    this.element.addEventListener('turbo:before-morph-attribute', this.preserveCollapseState)
  }

  disconnect () {
    this.element.removeEventListener('turbo:before-morph-attribute', this.preserveCollapseState)
  }

  preserveCollapseState = (event) => {
    if (isCollapsibleSectionState(event.target)) event.preventDefault()
  }
}
