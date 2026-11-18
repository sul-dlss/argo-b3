import { Controller } from '@hotwired/stimulus'
import { STORAGE_KEY } from 'controllers/facet_checkbox_controller'

// Ignores a saved checkbox that is too old to be from the visit it was saved for.
const MAX_AGE_MS = 30000

// On a checkbox facet's description, which is rendered each time the facet loads: returns focus to the
// checkbox that changed (see facet_checkbox_controller.js), or to the facet's toggle if the checkbox
// is not shown (e.g., the facet collapsed, or the value was on a later page of values).
export default class extends Controller {
  connect () {
    const saved = JSON.parse(window.sessionStorage.getItem(STORAGE_KEY) || 'null')
    if (saved?.facet !== this.element.id) return

    window.sessionStorage.removeItem(STORAGE_KEY)
    if (Date.now() - saved.at > MAX_AGE_MS) return

    // Deferred until the facet's values, rendered with this description, are connected.
    setTimeout(() => {
      const checkbox = document.getElementById(saved.id)
      const target = checkbox?.checkVisibility()
        ? checkbox
        : this.element.closest('.accordion-item')?.querySelector('.accordion-button')
      target?.focus()
    })
  }
}
