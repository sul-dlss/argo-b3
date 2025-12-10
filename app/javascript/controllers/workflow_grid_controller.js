import { Controller } from '@hotwired/stimulus'

// Reload the turbo-frame every 10 seconds
export default class extends Controller {
  start () {
    if (this.reloadInterval) return
    // If the element is empty, no need to refresh it.
    if (this.element.innerHTML.trim() === '') return
    this.reloadInterval = setInterval(() => {
      this.element.reload()
    }, 10000)
  }

  disconnect () {
    if (this.reloadInterval) clearInterval(this.reloadInterval)
  }
}
