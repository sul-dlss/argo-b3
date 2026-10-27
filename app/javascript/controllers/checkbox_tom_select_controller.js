import { Controller } from '@hotwired/stimulus'
import TomSelect from 'tom-select'
import MorphableTomSelect from 'controllers/morphable_tom_select'

// Connects a multiple select to Tom Select, with a checkbox for each option.
// Rather than listing the selected options, the control shows the number of selected options.
// Set the selectAll value to false to omit the Select all / Select none buttons.
export default class extends Controller {
  static values = { selectAll: { type: Boolean, default: true } }

  connect () {
    this.morphable = new MorphableTomSelect(this.element, {
      build: () => this.build(),
      destroy: (tomSelect) => this.destroyRetainingSelection(tomSelect)
    })
    this.morphable.connect()
  }

  build () {
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
    if (this.selectAllValue) this.addSelectAllButtons()
    return this.tomSelect
  }

  addSelectAllButtons () {
    const header = document.createElement('div')
    header.classList.add('ts-select-all', 'd-flex', 'gap-2', 'px-2', 'border-bottom')
    header.append(
      this.createButton('Select all', () => this.tomSelect.setValue(Object.keys(this.tomSelect.options))),
      this.createButton('Select none', () => this.tomSelect.clear())
    )
    this.tomSelect.dropdown.prepend(header)
  }

  createButton (text, onClick) {
    const button = document.createElement('button')
    button.type = 'button'
    button.classList.add('btn', 'btn-link', 'btn-sm', 'px-0')
    button.textContent = text
    // Prevents the control from losing focus, which would close the dropdown.
    button.addEventListener('mousedown', (event) => event.preventDefault())
    button.addEventListener('click', onClick)
    return button
  }

  disconnect () {
    this.morphable.disconnect()
  }

  // Destroying Tom Select restores the select's original options, so the selected values are reapplied.
  // This retains the selection when the select is moved, e.g., as a Turbo permanent element.
  destroyRetainingSelection (tomSelect) {
    const values = tomSelect.getValue()
    tomSelect.destroy()
    Array.from(this.element.options).forEach((option) => {
      option.selected = values.includes(option.value)
    })
  }

  updateCount = () => {
    this.count.textContent = `${this.tomSelect.items.length} selected`
  }
}
