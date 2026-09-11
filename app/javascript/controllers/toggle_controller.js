import { Controller } from '@hotwired/stimulus'

// Show or hide sections based on which toggle radio button is selected.
// Sections that are not shown are also disabled so that their fields are not submitted.
// This requires that a section is either a fieldset or an element whose direct children are
// fieldsets, since disabling a fieldset disables all of its fields without changing the
// disabled state of the individual fields.
// Mark the radio buttons with:
//   <input data-toggle-target="radio" data-toggle-section="with-embargo" data-action="toggle#toggle" type="radio"></input>
// Mark the sections with:
//   <fieldset data-toggle-target="section" data-toggle-section="with-embargo"></fieldset>
// or, when grouping several fieldsets:
//   <div data-toggle-target="section" data-toggle-section="with-embargo"><fieldset>...</fieldset></div>
// The value of data-toggle-section associates a radio button with its section. More than one
// section may share the same value.
export default class extends Controller {
  static targets = ['radio', 'section']

  connect () {
    this.showSelectedSection()
  }

  toggle () {
    this.showSelectedSection()
  }

  showSelectedSection () {
    const checkedRadio = this.radioTargets.find((radio) => radio.checked)
    const selectedSection = checkedRadio?.dataset.toggleSection
    this.sectionTargets.forEach((section) => {
      const hidden = section.dataset.toggleSection !== selectedSection
      section.classList.toggle('d-none', hidden)
      // Disabling the fieldsets keeps the hidden fields out of the submitted params.
      this.fieldsetsFor(section).forEach((fieldset) => { fieldset.disabled = hidden })
    })
  }

  // A section is either a fieldset itself or an element containing fieldsets. Only direct children
  // are returned, since the browser disables everything inside a disabled fieldset.
  fieldsetsFor (section) {
    return section.tagName === 'FIELDSET' ? [section] : section.querySelectorAll(':scope > fieldset')
  }
}
