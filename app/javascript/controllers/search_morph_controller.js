import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

// Updates a search page in place when visiting another search on the same page (e.g., selecting a facet value):
// the page is morphed instead of replaced and the scroll position is kept. Each element marked
// data-search-morph-keep keeps its content, inert, until its new content loads, instead of showing a loading
// placeholder: a marked turbo-frame reloads from its new src, and a marked facet is morphed by a turbo stream.
// Focus within a kept element, which inert removes, is returned once it is released.
export default class extends Controller {
  connect () {
    this.morphing = false
    this.keptFocus = null
    this.listeners = {
      'turbo:visit': this.visit,
      'turbo:before-render': this.beforeRender,
      'turbo:before-morph-element': this.beforeMorphElement,
      'turbo:before-morph-attribute': this.beforeMorphAttribute,
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
    if (currentElement.contains(document.activeElement)) {
      this.keptFocus = { element: document.activeElement, keptElement: currentElement }
    }
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

  // A facet whose And/Or toggle had focus stays expanded, even when no value is checked, so focus stays on the toggle.
  beforeMorphAttribute (event) {
    if (this.keptFocus?.element.closest('.toggle-radio') && this.keptFocus.keptElement.contains(event.target) &&
        event.target.matches('.accordion-button, .accordion-collapse')) event.preventDefault()
  }

  render () {
    if (!this.morphing) return

    this.morphing = false
    // No frame is reloading, so no stream will replace the kept facets.
    if (this.reloadingFrames === 0) this.releaseAll()
  }

  beforeStreamRender (event) {
    const render = event.detail.render
    event.detail.render = async (streamElement) => {
      const target = document.getElementById(streamElement.getAttribute('target'))
      target?.removeAttribute('inert')
      await render(streamElement)
      if (target) this.restoreFocus(target)
    }
  }

  frameLoad (event) {
    if (!event.target.hasAttribute('data-search-morph-keep')) return

    event.target.inert = false
    this.restoreFocus(event.target)
  }

  releaseAll () {
    document.querySelectorAll('[data-search-morph-keep][inert]').forEach((element) => {
      element.inert = false
      this.restoreFocus(element)
    })
  }

  // Focuses the element that had focus if the morph kept it, else the facet's toggle (e.g., the facet collapsed,
  // or a checked value is on a later page of values).
  restoreFocus (keptElement) {
    if (this.keptFocus?.keptElement !== keptElement) return

    const { element } = this.keptFocus
    this.keptFocus = null
    // Unless the user has moved focus elsewhere meanwhile.
    if (document.activeElement !== document.body) return

    const target = element.isConnected && element.checkVisibility()
      ? element
      : keptElement.querySelector('.accordion-button')
    target?.focus()
  }
}
