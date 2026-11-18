import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

export const STORAGE_KEY = 'facet-checkbox-focus'

// Updates the search when a facet checkbox changes, remembering the checkbox so that
// facet_checkbox_focus_controller.js can return focus to it once its facet reloads.
export default class extends Controller {
  static values = { url: String }

  navigate () {
    const saved = { id: this.element.id, facet: this.element.getAttribute('aria-describedby'), at: Date.now() }
    window.sessionStorage.setItem(STORAGE_KEY, JSON.stringify(saved))
    Turbo.visit(this.urlValue)
  }
}
