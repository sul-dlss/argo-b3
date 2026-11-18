import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

// Updates a search page in place when visiting another search on the same page (e.g., selecting a facet value):
// the page is morphed instead of replaced and the scroll position is kept. Each element marked
// data-search-morph-keep keeps its content, inert, until its new content loads, instead of showing a loading
// placeholder: a marked turbo-frame reloads from its new src, and a marked facet is updated by a turbo stream.
export default class extends Controller {
  connect () {
    this.morphing = false
    this.listeners = {
      'turbo:visit': this.visit,
      'turbo:before-render': this.beforeRender,
      'turbo:before-morph-element': this.beforeMorphElement,
      'turbo:render': this.render,
      'turbo:before-stream-render': this.beforeStreamRender,
      'turbo:frame-load': this.frameLoad,
      'turbo:fetch-request-error': this.releaseAll
    }
    Object.entries(this.listeners).forEach(([name, listener]) => {
      this.listeners[name] = listener.bind(this)
      document.addEventListener(name, this.listeners[name])
    })
  }

  disconnect () {
    Object.entries(this.listeners).forEach(([name, listener]) => document.removeEventListener(name, listener))
  }

  visit (event) {
    // Back and forward (restore) visits are morphed too, since these pages are not cached (turbo-cache-control).
    const samePage = new URL(event.detail.url, window.location.href).pathname === window.location.pathname
    this.morphing = samePage && ['advance', 'restore'].includes(event.detail.action)
  }

  beforeRender (event) {
    if (!this.morphing || !event.detail.newBody.querySelector('[data-controller~="search-morph"]')) return

    this.reloadingFrames = 0
    event.detail.render = (currentElement, newElement) => Turbo.morphElements(currentElement, newElement)
    // An advance visit scrolls to the top after rendering; the page loads within the same task, so this runs first.
    const { scrollX, scrollY } = window
    document.addEventListener('turbo:load', () => window.scrollTo(scrollX, scrollY), { once: true })
  }

  beforeMorphElement (event) {
    const { currentElement, newElement } = event.detail
    if (!currentElement.hasAttribute('data-search-morph-keep') || currentElement.id !== newElement.id) return

    event.preventDefault()
    const src = newElement.getAttribute('src')
    if (currentElement.tagName === 'TURBO-FRAME') {
      if (!src) return

      // Reloaded even when its src is unchanged, since the visit may follow a change (e.g., pinning a result).
      if (src === currentElement.getAttribute('src')) {
        currentElement.reload()
      } else {
        currentElement.src = src
      }
      this.reloadingFrames++
    }
    currentElement.inert = true
  }

  render () {
    if (!this.morphing) return

    this.morphing = false
    // No frame is reloading, so no stream will replace the kept facets.
    if (this.reloadingFrames === 0) this.releaseAll()
  }

  beforeStreamRender (event) {
    const render = event.detail.render
    // Released first, so that the new content can take focus (see facet_checkbox_controller.js).
    event.detail.render = (streamElement) => {
      document.getElementById(streamElement.getAttribute('target'))?.removeAttribute('inert')
      return render(streamElement)
    }
  }

  frameLoad (event) {
    if (event.target.hasAttribute('data-search-morph-keep')) event.target.inert = false
  }

  releaseAll () {
    document.querySelectorAll('[data-search-morph-keep][inert]').forEach((element) => { element.inert = false })
  }
}
