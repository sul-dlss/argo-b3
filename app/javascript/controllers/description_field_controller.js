import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  #debounceTimer = null
  #handleChange = (event) => {
    // Ignore hidden inputs and the JSON textarea itself (that syncs the other direction)
    if (event.target.type === 'hidden') return
    if (event.target.closest('[data-controller~="json-formatter"]')) return

    clearTimeout(this.#debounceTimer)
    this.#debounceTimer = setTimeout(() => this.#sendUpdate(), 400)
  }

  connect () {
    this.element.addEventListener('input', this.#handleChange)
    this.element.addEventListener('change', this.#handleChange)
  }

  disconnect () {
    this.element.removeEventListener('input', this.#handleChange)
    this.element.removeEventListener('change', this.#handleChange)
    clearTimeout(this.#debounceTimer)
  }

  #sendUpdate () {
    const fieldType = this.element.dataset.fieldType
    const urlContainer = this.element.closest('[data-field-json-url]')
    if (!fieldType || !urlContainer) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const params = new URLSearchParams({ field_type: fieldType })
    const selector = 'input:not([disabled]), select, textarea:not([disabled]):not([data-controller~="json-formatter"])'
    this.element.querySelectorAll(selector).forEach(el => {
      if (el.name) params.append(el.name, el.value)
    })

    fetch(urlContainer.dataset.fieldJsonUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-CSRF-Token': csrfToken },
      body: params.toString()
    })
      .then(response => response.ok ? response.json() : null)
      .then(json => {
        if (!json) return
        const textarea = this.element.querySelector('[data-controller~="json-formatter"]')
        if (!textarea) return
        textarea.value = JSON.stringify(json, null, 2)
      })
      .catch(() => {})
  }
}
