import { Controller } from '@hotwired/stimulus'

// Reload the turbo-frame every 15 seconds if it is in the viewport
export default class extends Controller {
  start () {
    if (this.reloadInterval) return
    // If the element is empty, no need to refresh it.
    if (this.element.innerHTML.trim() === '') return
    this.reloadInterval = setInterval(() => {
      this.reloadIfInViewport()
    }, 15000)
  }

  disconnect () {
    if (this.reloadInterval) clearInterval(this.reloadInterval)
  }

  reloadIfInViewport () {
    const observer = new IntersectionObserver((entries, observer) => { // eslint-disable-line no-undef
      const entry = entries[0]
      if (entry.isIntersecting) this.element.reload()
      observer.disconnect() // Stop observing after first check
    }, { root: null, threshold: 0 })

    observer.observe(this.element)
  }
}
