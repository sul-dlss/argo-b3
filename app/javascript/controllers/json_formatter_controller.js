import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect () {
    const collapse = this.element.closest('.collapse')
    if (collapse) {
      this.element.disabled = true
      collapse.addEventListener('show.bs.collapse', () => {
        this.element.disabled = false
      })
      collapse.addEventListener('shown.bs.collapse', () => {
        this.resize()
      })
      collapse.addEventListener('hide.bs.collapse', () => {
        this.element.disabled = true
      })
    }
    this.resize()
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
    } catch {
      this.element.classList.add('is-invalid')
    }
  }
}
