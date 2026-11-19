// Attributes Bootstrap sets on a dropdown's toggle and menu when it opens.
const OPEN_STATE_ATTRIBUTES = ['class', 'aria-expanded', 'style', 'data-bs-popper']

// Keeps an open Bootstrap dropdown (e.g., a header menu) open when Turbo morphs the page (e.g., on a
// page refresh), which would otherwise reset its toggle and menu to the closed state the server rendered.
// A closed dropdown is morphed as usual, so its markup still updates.
export function preserveOpenDropdowns (event) {
  if (!OPEN_STATE_ATTRIBUTES.includes(event.detail.attributeName)) return
  if (isOpenDropdownPart(event.target)) event.preventDefault()
}

// Whether the element is the toggle or menu of an open dropdown.
export function isOpenDropdownPart (element) {
  if (!element.matches('[data-bs-toggle="dropdown"], .dropdown-menu')) return false

  return element.parentElement?.querySelector(':scope > .dropdown-menu.show') !== null
}
