import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

const STORAGE_KEY = 'facet-checkbox-focus'
// Ignores a saved focus that is too old to be from the visit it was saved for.
const MAX_AGE_MS = 30000

// Updates the search when a facet checkbox changes, then returns focus to the checkbox once its facet reloads.
export default class extends Controller {
  static values = { url: String }

  connect () {
    const saved = JSON.parse(window.sessionStorage.getItem(STORAGE_KEY) || 'null')
    if (saved?.id !== this.element.id) return

    window.sessionStorage.removeItem(STORAGE_KEY)
    if (Date.now() - saved.at > MAX_AGE_MS) return

    // When the facet has collapsed (e.g., its last value was unchecked), focus its toggle instead.
    const target = this.element.checkVisibility()
      ? this.element
      : this.element.closest('.accordion-item')?.querySelector('.accordion-button')
    target?.focus()
  }

  navigate () {
    window.sessionStorage.setItem(STORAGE_KEY, JSON.stringify({ id: this.element.id, at: Date.now() }))
    Turbo.visit(this.urlValue)
  }
}
