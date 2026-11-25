import { Controller } from '@hotwired/stimulus'

// Hides and disables the new User Version question while the view access is dark, since a dark object's previous
// User Versions are permanently withdrawn. A disabled fieldset's radios are not submitted, so No is deposited.
// Without a view access select on the page (e.g., the manage files deposit step), the rendered state is kept.
export default class extends Controller {
  connect () {
    this.update()
  }

  update () {
    // The enabled select is the one in effect, since the embargo toggle disables the hidden section's select.
    const viewSelect = document.querySelector('select[name$="[access_view]"]:enabled')
    if (!viewSelect) return

    const dark = viewSelect.value === 'dark'
    this.element.hidden = dark
    this.element.disabled = dark
  }
}
