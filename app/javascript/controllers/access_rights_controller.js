import { Controller } from '@hotwired/stimulus'

// Download options permitted for each view option.
const DOWNLOAD_OPTIONS_BY_VIEW = {
  world: ['world', 'stanford', 'location-based', 'none'],
  dark: ['none'],
  'citation-only': ['none'],
  stanford: ['stanford', 'location-based', 'none'],
  'location-based': ['location-based', 'none']
}

// This controller is used to toggle access rights options on the manage rights bulk action form.
export default class extends Controller {
  static targets = ['view', 'download', 'location']

  connect () {
    this.toggle()
  }

  toggle () {
    this.enableOptions(this.downloadTarget, DOWNLOAD_OPTIONS_BY_VIEW[this.viewTarget.value] ?? [])
    // Read the download value after enableOptions, which may have changed it.
    this.locationTarget.disabled = this.viewTarget.value !== 'location-based' &&
      this.downloadTarget.value !== 'location-based'
  }

  enableOptions (select, enabledValues) {
    Array.from(select.options).forEach((option) => {
      option.disabled = !enabledValues.includes(option.value)
    })
    this.selectFirstEnabledIfNeeded(select)
  }

  selectFirstEnabledIfNeeded (select) {
    if (!select.selectedOptions[0]?.disabled) return
    const firstEnabledOption = Array.from(select.options).find((option) => !option.disabled)
    if (firstEnabledOption) select.value = firstEnabledOption.value
  }
}
