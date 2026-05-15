import { Controller } from '@hotwired/stimulus'

// This controller is used to toggle access rights inputs on the manage rights bulk action form.
export default class extends Controller {
  static targets = [
    'worldView', 'darkView', 'citationOnlyView', 'stanfordView', 'locationBasedView',
    'worldDownload', 'noneDownload', 'stanfordDownload', 'locationBasedDownload',
    'location'
  ]

  connect () {
    this.toggle()
  }

  toggle () {
    if (this.selectedViewTarget === this.worldViewTarget) {
      this.disableExcept(this.downloadTargets, this.downloadTargets)
    } else if (this.selectedViewTarget === this.darkViewTarget || this.selectedViewTarget === this.citationOnlyViewTarget) {
      this.disableExcept(this.downloadTargets, [this.noneDownloadTarget])
    } else if (this.selectedViewTarget === this.locationBasedViewTarget) {
      this.disableExcept(this.downloadTargets, [this.locationBasedDownloadTarget, this.noneDownloadTarget])
    } else if (this.selectedViewTarget === this.stanfordViewTarget) {
      this.disableExcept(this.downloadTargets, [this.stanfordDownloadTarget, this.locationBasedDownloadTarget, this.noneDownloadTarget])
    }

    this.toggleLocations(this.selectedViewTarget !== this.locationBasedViewTarget && this.selectedDownloadTarget !== this.locationBasedDownloadTarget)
  }

  disableExcept (targets, exceptTargets) {
    targets.forEach((target) => {
      target.disabled = !exceptTargets.includes(target)
    })
    this.checkFirstIfNeeded(exceptTargets)
  }

  toggleLocations (disabled) {
    this.locationTargets.forEach((target) => {
      target.disabled = disabled
    })
    this.checkFirstIfNeeded(this.locationTargets)
  }

  checkFirstIfNeeded (targets) {
    if (targets.some((target) => target.checked)) return
    const firstEnabledTarget = targets.find((target) => !target.disabled)
    if (firstEnabledTarget) firstEnabledTarget.checked = true
  }

  get viewTargets () {
    return [this.worldViewTarget, this.darkViewTarget, this.citationOnlyViewTarget, this.stanfordViewTarget, this.locationBasedViewTarget]
  }

  get selectedViewTarget () {
    return this.viewTargets.find((target) => target.checked)
  }

  get downloadTargets () {
    return [this.worldDownloadTarget, this.stanfordDownloadTarget, this.locationBasedDownloadTarget, this.noneDownloadTarget]
  }

  get selectedDownloadTarget () {
    return this.downloadTargets.find((target) => target.checked)
  }
}
