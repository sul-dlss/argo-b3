import { Controller } from '@hotwired/stimulus'
import TomSelect from 'tom-select'
import MorphableTomSelect from 'controllers/morphable_tom_select'

// Connects a multiple select to Tom Select, with a checkbox for each option.
// Rather than listing the selected options, the control holds only the filter input and the number of selected
// options is shown below it, with Select all / Select none buttons that can be reached by keyboard.
// Set the selectAll value to false to omit the Select all / Select none buttons.
export default class extends Controller {
  static values = { selectAll: { type: Boolean, default: true } }

  connect () {
    this.morphable = new MorphableTomSelect(this.element, {
      build: () => this.build(),
      destroy: (tomSelect) => this.destroyRetainingSelection(tomSelect),
      companions: () => [this.footer]
    })
    this.morphable.connect()
  }

  build () {
    this.tomSelect = new TomSelect(this.element, {
      plugins: ['checkbox_options', 'no_backspace_delete'],
      create: false,
      maxItems: null,
      // List every option, rather than Tom Select's default of the first 50.
      maxOptions: null,
      hideSelected: false,
      closeAfterSelect: false,
      placeholder: 'Type to filter',
      // Selected options are summarized by the count, so the items are not displayed.
      render: {
        item: () => '<div class="d-none"></div>'
      }
    })

    this.exposeSelection()
    this.buildFooter()
    this.tomSelect.on('change', this.updateCount)
    this.updateCount()
    return this.tomSelect
  }

  // Tom Select marks the highlighted option as aria-selected, so screen readers announce every option as selected.
  // Instead, the listbox is multiselectable and aria-selected follows the selection (the highlighted option is
  // identified by aria-activedescendant). The checkboxes only show the selection, so they are hidden from screen readers.
  exposeSelection () {
    this.tomSelect.dropdown_content.setAttribute('aria-multiselectable', 'true')
    for (const method of ['setActiveOption', 'clearActiveOption', 'refreshOptions']) {
      this.tomSelect.hook('after', method, this.updateSelectedOptions)
    }
    this.tomSelect.on('item_add', this.updateSelectedOptions)
    this.tomSelect.on('item_remove', this.updateSelectedOptions)
  }

  updateSelectedOptions = () => {
    this.tomSelect.dropdown_content.querySelectorAll('[role="option"]').forEach((option) => {
      option.setAttribute('aria-selected', this.tomSelect.items.includes(option.dataset.value).toString())
      const checkbox = option.querySelector('input[type="checkbox"]')
      if (checkbox) {
        checkbox.setAttribute('aria-hidden', 'true')
        checkbox.tabIndex = -1
      }
    })
  }

  // The count and buttons follow the control, outside the dropdown, so they are visible while it is closed and the
  // buttons are in the tab order. The count describes the input and announces changes.
  buildFooter () {
    this.footer?.remove()
    this.footer = document.createElement('div')
    this.footer.classList.add('ts-footer', 'd-flex', 'flex-wrap', 'align-items-baseline', 'column-gap-3', 'form-text')

    this.count = document.createElement('span')
    this.count.id = `${this.tomSelect.inputId}-count`
    this.count.classList.add('ts-count')
    this.count.setAttribute('aria-live', 'polite')
    this.footer.append(this.count)

    const describedBy = [this.element.getAttribute('aria-describedby'), this.count.id].filter(Boolean).join(' ')
    this.tomSelect.control_input.setAttribute('aria-describedby', describedBy)

    if (this.selectAllValue) {
      // Named for the field, since a form may have several of these selects.
      const fieldName = this.morphable.label?.textContent.trim().toLowerCase()
      // Grouped so that, in a narrow field, both buttons wrap below the count.
      const buttons = document.createElement('span')
      buttons.classList.add('d-flex', 'column-gap-3')
      buttons.append(
        this.createButton('Select all', fieldName, () => this.tomSelect.setValue(Object.keys(this.tomSelect.options))),
        this.createButton('Select none', fieldName, () => this.tomSelect.clear())
      )
      this.footer.append(buttons)
    }
    this.tomSelect.wrapper.after(this.footer)
  }

  createButton (text, fieldName, onClick) {
    const button = document.createElement('button')
    button.type = 'button'
    button.classList.add('btn', 'btn-link', 'btn-sm', 'p-0')
    button.textContent = text
    if (fieldName) button.setAttribute('aria-label', `${text} ${fieldName}`)
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
    this.footer?.remove()
    this.footer = null
    Array.from(this.element.options).forEach((option) => {
      option.selected = values.includes(option.value)
    })
  }

  updateCount = () => {
    const total = Object.keys(this.tomSelect.options).length
    this.count.textContent = `${this.tomSelect.items.length} of ${total} selected`
  }
}
