import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect () {
    this.resize()
  }

  resize () {
    this.element.style.height = 'auto'
    this.element.style.height = `${this.element.scrollHeight}px`
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
