import { Controller } from '@hotwired/stimulus'

// Manages the dynamic addition and removal of array items in the description editor.
export default class extends Controller {
  addItem (event) {
    event.preventDefault()
    const list = document.getElementById(event.currentTarget.dataset.listId)
    const template = document.getElementById(event.currentTarget.dataset.templateId)
    list.appendChild(template.content.cloneNode(true))
  }

  removeItem (event) {
    event.preventDefault()
    event.currentTarget.closest('[data-item]').remove()
  }
}
