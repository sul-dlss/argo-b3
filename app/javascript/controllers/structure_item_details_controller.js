import { Controller } from '@hotwired/stimulus'

// Reloads the structure frame for the selected content type and access, so that structuring uses them
// before they are saved.
export default class extends Controller {
  static targets = ['frame']
  static values = { accessFields: Array, paramKey: String }

  // Called for a change to any of the item details, so the event's target is a field of the item form.
  update (event) {
    const url = new URL(this.frameTarget.src, window.location.origin)
    // Fields in disabled (hidden) fieldsets are not in the form data, so their previous values are removed.
    this.accessFieldsValue.forEach((field) => url.searchParams.delete(this.paramName(field)))

    const formData = new FormData(event.target.form)
    url.searchParams.set('content_type', formData.get(this.paramName('content_type')) ?? '')
    this.accessFieldsValue.forEach((field) => {
      const value = formData.get(this.paramName(field))
      if (value !== null) url.searchParams.set(this.paramName(field), value)
    })
    this.frameTarget.src = url.toString()
  }

  paramName (field) {
    return `${this.paramKeyValue}[${field}]`
  }
}
