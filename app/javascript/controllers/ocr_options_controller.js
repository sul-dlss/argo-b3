import { Controller } from '@hotwired/stimulus'

// Enables the OCR section only for content types that can be OCRed, and the language selector only
// when OCR has been requested. Disabling rather than hiding keeps the fields out of the submitted
// params without changing which of them are selected, so previous selections are shown again when
// the fields are re-enabled; the form clears the values that were not submitted.
// Mark the content type select with:
//   <select data-ocr-options-target="contentType" data-action="ocr-options#toggle"></select>
// Mark the section holding the Run OCR? radios, which must be a fieldset so that disabling it
// disables the radios:
//   <fieldset data-ocr-options-target="section"></fieldset>
// Mark each Run OCR? radio with:
//   <input type="radio" data-ocr-options-target="runOcr" data-action="ocr-options#toggle">
// Mark the language selector's multi-select container with:
//   <div data-ocr-options-target="languages"></div>
// Mark any warning with the content types it applies to; it is shown only while OCR is requested:
//   <div data-ocr-options-target="warning" data-ocr-options-warn-content-types='["..."]'></div>
export default class extends Controller {
  static targets = ['contentType', 'section', 'runOcr', 'languages', 'warning']
  static values = { allowedContentTypes: Array }

  connect () {
    this.toggle()
  }

  toggle () {
    const ocrAllowed = this.allowedContentTypesValue.includes(this.contentTypeTarget.value)
    this.sectionTarget.disabled = !ocrAllowed

    const ocrRequested = this.runOcrTargets.some((radio) => radio.checked && radio.value === 'true')
    // The multi-select controller owns the tom-select widget, so ask it to disable itself rather
    // than relying on the disabled fieldset, which leaves the widget interactive.
    this.languagesTarget.dataset.multiSelectDisabledValue = String(!(ocrAllowed && ocrRequested))

    this.warningTargets.forEach((warning) => {
      const warnFor = JSON.parse(warning.dataset.ocrOptionsWarnContentTypes)
      const applies = ocrRequested && warnFor.includes(this.contentTypeTarget.value)
      warning.classList.toggle('d-none', !applies)
    })
  }
}
