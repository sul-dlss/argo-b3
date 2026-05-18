import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  #collapse = null
  #onShow = () => { this.element.disabled = false }
  #onShown = () => { this.resize() }
  #onHide = () => { this.element.disabled = true }

  connect () {
    const collapse = this.element.closest('.collapse')
    if (collapse) {
      this.element.disabled = !collapse.classList.contains('show')
      collapse.addEventListener('show.bs.collapse', this.#onShow)
      collapse.addEventListener('shown.bs.collapse', this.#onShown)
      collapse.addEventListener('hide.bs.collapse', this.#onHide)
      this.#collapse = collapse
    }
    this.resize()
  }

  disconnect () {
    if (this.#collapse) {
      this.#collapse.removeEventListener('show.bs.collapse', this.#onShow)
      this.#collapse.removeEventListener('shown.bs.collapse', this.#onShown)
      this.#collapse.removeEventListener('hide.bs.collapse', this.#onHide)
    }
  }

  resize () {
    this.element.style.height = 'auto'
    this.element.style.height = `${Math.max(this.element.scrollHeight, 160)}px`
  }

  format () {
    try {
      const parsed = JSON.parse(this.element.value)
      this.element.value = JSON.stringify(parsed, null, 2)
      this.element.classList.remove('is-invalid')
      this.resize()
      this.syncToForm()
    } catch {
      this.element.classList.add('is-invalid')
    }
  }

  syncToForm () {
    // Only sync json_toggle textareas (inside .collapse), not the "must edit as JSON" fallback ones
    const collapse = this.element.closest('.collapse')
    if (!collapse) return

    const dataItem = this.element.closest('[data-item]')
    if (!dataItem) return

    const fieldType = dataItem.dataset.fieldType
    if (!fieldType) return

    const urlContainer = this.element.closest('[data-render-field-url]')
    if (!urlContainer) return

    const url = urlContainer.dataset.renderFieldUrl
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrfToken },
      body: JSON.stringify({ field_type: fieldType, json: this.element.value })
    })
      .then(response => response.ok ? response.text() : null)
      .then(html => {
        if (!html) return
        const temp = document.createElement('div')
        temp.innerHTML = html
        const newItem = temp.firstElementChild
        if (!newItem) return

        // Re-open the collapse so the user can keep editing
        const newCollapse = newItem.querySelector('.collapse')
        if (newCollapse) {
          newCollapse.classList.add('show')
          const toggleBtn = newItem.querySelector('[data-bs-toggle="collapse"]')
          if (toggleBtn) toggleBtn.setAttribute('aria-expanded', 'true')
        }

        dataItem.replaceWith(newItem)
      })
      .catch(() => {})
  }
}
