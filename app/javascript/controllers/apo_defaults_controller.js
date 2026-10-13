import { Controller } from '@hotwired/stimulus'

// Fields that are filled by a single input, keyed by their name in the endpoint's response.
const TERMS_FIELDS = {
  use_and_reproduction_statement: 'useAndReproductionStatement',
  copyright: 'copyright',
  license: 'license'
}

// Access fields, in the order they are applied: access-rights enables the download and location options
// based on the view (and download), so view must be set first.
const ACCESS_FIELDS = ['view', 'download', 'location']

// Applies the selected APO's object defaults to the rights fields of the item form.
// Each APO option has the URL of the APO's defaults, which returns, for each field,
// { "value": "..." or null, "text": "APO default = ..." }.
// Mark the APO select and its options with:
//   <select data-apo-defaults-target="apo" data-action="apo-defaults#apply">
//     <option value="druid:..." data-apo-defaults-url="/apo_defaults/druid:..."></option>
//   </select>
// Mark each field input and the help text element that shows its default with, e.g.:
//   <textarea data-apo-defaults-target="copyright"></textarea> <span data-apo-defaults-target="copyrightText"></span>
export default class extends Controller {
  static targets = ['apo', 'useAndReproductionStatement', 'useAndReproductionStatementText', 'copyright',
    'copyrightText', 'license', 'licenseText', 'accessGroup']

  static values = { applyOnConnect: Boolean }

  // A new form applies the defaults of the initially selected APO. When the form is redisplayed (e.g., after
  // a failed submission), applyOnConnect is false and only the help text is shown, so that values the user
  // entered after selecting the APO are not overwritten.
  connect () {
    this.update({ applyValues: this.applyOnConnectValue })
  }

  apply () {
    this.update({ applyValues: true })
  }

  async update ({ applyValues }) {
    // There is no selected APO when the user has no APOs to register with.
    const option = this.apoTarget.selectedOptions[0]
    if (!option) return

    const druid = option.value
    const defaults = await this.fetchDefaults(option.dataset.apoDefaultsUrl)
    // The selection may have changed while fetching.
    if (!defaults || druid !== this.apoTarget.value) return

    this.showHelpTexts(defaults)
    if (applyValues) this.applyValues(defaults)
  }

  async fetchDefaults (url) {
    try {
      const response = await fetch(url, { headers: { Accept: 'application/json' } })
      if (!response.ok) throw new Error(`APO defaults request failed with status ${response.status}`)

      return await response.json()
    } catch (error) {
      console.error(error)
      return null
    }
  }

  showHelpTexts (defaults) {
    Object.entries(TERMS_FIELDS).forEach(([field, target]) => {
      this.textTargetsFor(target).forEach((element) => { element.textContent = defaults[field].text })
    })
    this.accessGroupTargets.forEach((group) => {
      ACCESS_FIELDS.forEach((field) => {
        group.querySelectorAll(`[data-apo-defaults-field="${field}"]`)
          .forEach((element) => { element.textContent = defaults[field].text })
      })
    })
  }

  applyValues (defaults) {
    Object.entries(TERMS_FIELDS).forEach(([field, target]) => {
      this.inputTargetsFor(target).forEach((input) => this.setValue(input, defaults[field].value))
    })

    // A group in the hidden embargo section is disabled, so its values are not submitted until it is shown.
    this.accessGroupTargets.forEach((group) => {
      ACCESS_FIELDS.forEach((field) => {
        const select = group.querySelector(`[data-access-rights-target="${field}"]`)
        if (select) this.setValue(select, defaults[field].value)
      })
    })
  }

  // Sets the value, or clears it when the value is null or not an option of a select: a select is cleared
  // to its blank option (e.g., no license) or, without one (e.g., location), to no selection.
  // The change event lets other controllers respond, e.g., access-rights enabling the download options
  // for the view, and sdr-tab-error clearing a previously reported error for the field.
  setValue (input, value) {
    const newValue = value ?? ''
    if (this.hasOption(input, newValue)) {
      input.value = newValue
    } else if (this.hasOption(input, '')) {
      input.value = ''
    } else {
      input.selectedIndex = -1
    }
    input.dispatchEvent(new Event('change', { bubbles: true }))
  }

  hasOption (input, value) {
    return input.tagName !== 'SELECT' || Array.from(input.options).some((option) => option.value === value)
  }

  inputTargetsFor (target) {
    return this.targets.findAll(target)
  }

  textTargetsFor (target) {
    return this.targets.findAll(`${target}Text`)
  }
}
