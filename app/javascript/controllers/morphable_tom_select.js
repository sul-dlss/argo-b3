// Keeps a Tom Select widget working across Turbo morphs: a widget in use (open, focused or with an unsubmitted
// change) is skipped by the morph; otherwise it is rebuilt from the morphed input (e.g., resetting a submitted form).
export default class MorphableTomSelect {
  // @param input [HTMLElement] the select or input that Tom Select is attached to
  // @param build [Function] creates the widget and returns it
  // @param destroy [Function] tears down the widget when the controller disconnects
  constructor (input, { build, destroy = (tomSelect) => tomSelect.destroy() }) {
    this.input = input
    this.buildWidget = build
    this.destroyWidget = destroy
  }

  connect () {
    this.connected = true
    this.build()
    document.addEventListener('turbo:before-morph-element', this.beforeMorphElement)
    this.input.form?.addEventListener('submit', this.captureSubmittedValue)
  }

  disconnect () {
    this.connected = false
    document.removeEventListener('turbo:before-morph-element', this.beforeMorphElement)
    this.input.form?.removeEventListener('submit', this.captureSubmittedValue)
    if (this.tomSelect) this.destroyWidget(this.tomSelect)
    this.tomSelect = null
  }

  build () {
    // Found before building, since Tom Select points the label at its own control.
    this.label = this.input.id ? document.querySelector(`label[for="${window.CSS.escape(this.input.id)}"]`) : null
    this.tomSelect = this.buildWidget()
    this.captureSubmittedValue()
  }

  beforeMorphElement = (event) => {
    if (!this.tomSelect) return

    const { target } = event
    // The input is being removed, so disconnect tears down the widget.
    if (target === this.input && !event.detail.newElement) return
    if (![this.input, this.tomSelect.wrapper, this.label].includes(target)) return

    if (this.inUse()) {
      event.preventDefault()
    } else if (target === this.input) {
      this.rebuild()
    }
  }

  // Torn down before the input is morphed and rebuilt once the (synchronous) morph is done, since a widget
  // added mid-morph would be morphed into the elements that follow the input.
  rebuild () {
    this.tomSelect.destroy()
    this.tomSelect = null
    queueMicrotask(() => {
      if (this.connected && this.input.isConnected) this.build()
    })
  }

  inUse () {
    return this.tomSelect.isOpen || this.tomSelect.isFocused || this.currentValue() !== this.submittedValue
  }

  captureSubmittedValue = () => {
    if (this.tomSelect) this.submittedValue = this.currentValue()
  }

  currentValue () {
    return [this.tomSelect.getValue()].flat().sort().join('\u0000')
  }
}
