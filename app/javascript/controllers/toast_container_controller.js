import { Controller } from '@hotwired/stimulus'

// Shows a toast for an action that happens only in the browser, by adding a copy of the layout's toast template
// to the toast container. (Toasts from the server are appended by turbo streams instead.)
// Show one from any Stimulus controller with:
//   this.dispatch('show', { prefix: 'toast', detail: { title: 'Done' } })
// Pass the title from the server (e.g., as a Stimulus value or action param) so that it comes from the locale.
export default class extends Controller {
  show ({ detail: { title } }) {
    const toast = document.getElementById('toast-template').content.cloneNode(true)
    toast.querySelector('[data-toast-title]').textContent = title
    this.element.append(toast)
  }
}
