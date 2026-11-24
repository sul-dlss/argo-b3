import { Controller } from '@hotwired/stimulus'

// Scrolls to and focuses an element when it is rendered (e.g., the results of a check that has just finished),
// so that the page opens at it and a screen reader reads it.
// Put the controller on the element to focus, or on a container with a focus target (e.g., a radio group's first
// radio button). An element that is not otherwise focusable (e.g., a heading or an alert) is given tabindex="-1",
// so that it can be focused and the next Tab moves on from it.
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
    element.scrollIntoView({ block: 'start' })
    this.scrollBelowToasts(element)
  }

  // Toasts are fixed at the top of the window, so scroll the element down below any that cover it.
  scrollBelowToasts (element) {
    const toasts = [...document.querySelectorAll('#toast-container .toast')]
    if (toasts.length === 0) return

    const elementRect = element.getBoundingClientRect()
    const overlapping = toasts.map((toast) => toast.getBoundingClientRect())
      .filter((toastRect) => toastRect.left < elementRect.right && toastRect.right > elementRect.left &&
        toastRect.top < elementRect.bottom)
    if (overlapping.length === 0) return

    const toastsBottom = Math.max(...overlapping.map((toastRect) => toastRect.bottom))
    window.scrollBy(0, elementRect.top - toastsBottom - 16)
  }
}
