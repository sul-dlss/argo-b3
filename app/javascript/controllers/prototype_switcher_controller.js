// PROTOTYPE (throwaway, never merge): arrow keys cycle variants; renders a sample toast.
import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

export default class extends Controller {
  static targets = ['toast']
  static values = { prev: String, next: String }

  connect () {
    this.onKey = (event) => {
      if (event.target.closest('input, textarea, select, [contenteditable]')) return
      if (event.key === 'ArrowLeft') Turbo.visit(this.prevValue)
      if (event.key === 'ArrowRight') Turbo.visit(this.nextValue)
    }
    document.addEventListener('keydown', this.onKey)
  }

  disconnect () {
    document.removeEventListener('keydown', this.onKey)
  }

  toast () {
    document.getElementById('toast-container').append(this.toastTarget.content.cloneNode(true))
  }
}
