import { Controller } from '@hotwired/stimulus'
import TomSelect from 'tom-select'

// Connects a multiple select to Tom Select, with a checkbox for each option.
// Rather than listing the selected options, the control shows the number of selected options.
export default class extends Controller {
  connect () {
    this.tomSelect = new TomSelect(this.element, {
      plugins: ['checkbox_options', 'no_backspace_delete'],
      create: false,
      maxItems: null,
      hideSelected: false,
      closeAfterSelect: false,
      // Selected options are summarized by the count, so the items are not displayed.
      render: {
        item: () => '<div class="d-none"></div>'
      }
    })

    this.count = document.createElement('span')
    this.count.classList.add('ts-count')
    this.tomSelect.control.prepend(this.count)
    this.tomSelect.on('change', this.updateCount)
    this.updateCount()
  }

  // Destroying Tom Select restores the select's original options, so the selected values are reapplied.
  // This retains the selection when the select is moved, e.g., as a Turbo permanent element.
  disconnect () {
    if (!this.tomSelect) return

    const values = this.tomSelect.getValue()
    this.tomSelect.destroy()
    Array.from(this.element.options).forEach((option) => {
      option.selected = values.includes(option.value)
    })
  }

  updateCount = () => {
    this.count.textContent = `${this.tomSelect.items.length} selected`
  }
}
