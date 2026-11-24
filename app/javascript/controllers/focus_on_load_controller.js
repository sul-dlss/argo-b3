import { Controller } from '@hotwired/stimulus'

// Scrolls to and focuses an element when it is rendered (e.g., the results of a check that has just finished),
// so that the page opens at it and a screen reader reads it.
// Put the controller on the element to scroll to and focus, or on a container to scroll to with a focus target in it
// (e.g., a radio group, so that its legend is in view, with its first radio button focused). An element that is not
// otherwise focusable (e.g., a heading or an alert) is given tabindex="-1", so that it can be focused and the next Tab
// moves on from it.
export default class extends Controller {
  static targets = ['focus']

  connect () {
    // Deferred so that Turbo's own scrolling after rendering (e.g., to the top of the page) happens first.
    window.requestAnimationFrame(() => this.focus())
  }

  focus () {
    const element = this.hasFocusTarget ? this.focusTarget : this.element
    if (!element.matches('a[href], button, input, select, textarea, [tabindex]')) {
      element.setAttribute('tabindex', '-1')
    }

    element.focus({ preventScroll: true })
    this.element.scrollIntoView({ block: 'start' })
    this.scrollBelowToasts()
    this.removeController()
  }

  // Toasts are fixed at the top of the window, so scroll the element down below any that cover it.
  scrollBelowToasts () {
    const toasts = [...document.querySelectorAll('#toast-container .toast')]
    if (toasts.length === 0) return

    const elementRect = this.element.getBoundingClientRect()
    const overlapping = toasts.map((toast) => toast.getBoundingClientRect())
      .filter((toastRect) => toastRect.left < elementRect.right && toastRect.right > elementRect.left &&
        toastRect.top < elementRect.bottom)
    if (overlapping.length === 0) return

    const toastsBottom = Math.max(...overlapping.map((toastRect) => toastRect.bottom))
    window.scrollBy(0, elementRect.top - toastsBottom - 16)
  }

  // Focusing happens only once, so that the page does not open at the element again when Turbo restores it from its
  // cache (e.g., on going back to it).
  removeController () {
    const controllers = this.element.dataset.controller.split(' ').filter((name) => name !== this.identifier)
    if (controllers.length > 0) {
      this.element.dataset.controller = controllers.join(' ')
    } else {
      delete this.element.dataset.controller
    }
  }
}
