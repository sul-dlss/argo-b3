import { Controller } from '@hotwired/stimulus'

// Attributes Bootstrap (and Popper, for dropdowns outside a navbar) set on a dropdown's toggle and menu
// when it opens.
const OPEN_STATE_ATTRIBUTES = ['class', 'aria-expanded', 'style', 'data-bs-popper']

// Keeps an open Bootstrap dropdown (e.g., a header menu) open when Turbo morphs the page (e.g., on a
// page refresh), which would otherwise reset its toggle and menu to the closed state the server rendered.
// A closed dropdown is morphed as usual, so its markup still updates.
// Attached to the body, so it covers every page and every dropdown.
export default class extends Controller {
  connect () {
    this.element.addEventListener('turbo:before-morph-attribute', this.preserveOpenState)
  }

  disconnect () {
    this.element.removeEventListener('turbo:before-morph-attribute', this.preserveOpenState)
  }

  preserveOpenState = (event) => {
    const { attributeName } = event.detail
    if (!OPEN_STATE_ATTRIBUTES.includes(attributeName) && !attributeName.startsWith('data-popper-')) return

    if (this.isOpenDropdownPart(event.target)) event.preventDefault()
  }

  // Whether the element is the toggle or menu of an open dropdown.
  isOpenDropdownPart (element) {
    if (!element.matches('[data-bs-toggle="dropdown"], .dropdown-menu')) return false

    return element.parentElement?.querySelector(':scope > .dropdown-menu.show') !== null
  }
}
