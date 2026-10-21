import { Controller } from '@hotwired/stimulus'
import Dropzone from 'dropzone'

// Copied from H3
export default class extends Controller {
  static outlets = ['reloadable-frame', 'sdr-tab-error', 'form-error']
  static targets = ['progress', 'error', 'folderAlert', 'folderAlertText']
  static values = {
    maxFilesize: Number,
    hiddenInputContainerSelector: { type: String, default: '#dropzone-hidden-input-container' }
  }

  // Expected error handling behavior:
  // - A blank directory is ignored.
  // - Files that are larger than maxFilesize will not be uploaded.
  // - Error messages are cleared when the next file is added.

  connect () {
    this.dropzone = new Dropzone(this.element, {
      paramName: 'content[files]',
      uploadMultiple: true,
      createImageThumbnails: false,
      addRemoveLinks: false,
      disablePreviews: true,
      maxFilesize: this.maxFilesizeValue,
      hiddenInputContainer: this.hiddenInputContainerSelectorValue
    })
    this.progress = 0
    this.disablers = new Set()
    this.disabled = false
    this.shouldClearErrors = false
    this.basePath = null
    this.dropzone.on('processingmultiple', () => {
      this.element.dataset.dropzoneReady = false
      // Using processingmultiple instead of addedfiles for showing the progress bar
      // since addedfiles is triggered by dropping an empty directory.
      // This is not.
      this.progressTarget.classList.remove('d-none')
      // This shows the user that something is going on since there may be a paused before first progress.
      this.updateProgress(2)

      // This notifies the unsaved changes controller that the form has changed.
      this.element.dispatchEvent(new Event('change'))

      this.clearErrors()

      // This notifies listeners (e.g., disable-actions) that an upload has started.
      this.dispatch('upload-start')
    })
    this.dropzone.on('totaluploadprogress', (totalUploadProgress) => {
      const uploadProgress = Math.trunc(totalUploadProgress)
      this.updateProgress(uploadProgress)
    })
    this.dropzone.on('queuecomplete', async () => {
      this.shouldClearErrors = true
      // Give the user a second to process the 100% progress
      await new Promise(resolve => setTimeout(resolve, 1000))
      this.dropzone.element.classList.remove('dz-started')
      this.progressTarget.classList.add('d-none')
      this.updateProgress(0, true)
      // Reload the files sections (reloadable-frame outlets) to show the newly uploaded files.
      this.reloadableFrameOutlets.forEach(reloadableFrame => reloadableFrame.reload())
      if (this.hasSdrTabErrorOutlet) this.sdrTabErrorOutlet.clearInvalidStatus('files')
      if (this.hasFormErrorOutlet) this.formErrorOutlet.changedFiles()
      this.element.dataset.dropzoneReady = true
      this.dispatch('upload-end')
    })
    this.dropzone.on('sendingmultiple', (files, xhr, data) => {
      // Add the full path of each file to the form data
      for (let i = 0; i < files.length; i++) {
        const file = files[i]
        let path = file.fullPath ? file.fullPath : file.name
        // this.basePath is set when the user selects a folder to upload to.
        if (this.basePath) path = `${this.basePath}/${path}`
        data.append(`content[paths][${i}]`, path)
      }
    })
    this.dropzone.on('errormultiple', (files, message) => {
      this.clearErrors()

      this.errorTarget.classList.remove('d-none')
      files.forEach(file => {
        const errorElement = document.createElement('li')
        errorElement.textContent = `${file.name}: ${message}`
        this.errorTarget.appendChild(errorElement)
      })
    })
  }

  // Clear errors if this is the first error in the batch.
  clearErrors () {
    if (!this.shouldClearErrors) return
    this.errorTarget.innerHTML = ''
    this.shouldClearErrors = false
  }

  updateProgress (progress, reset = false) {
    // For some reason progress bounces around a bit. This keeps the progress moving forward.
    if (progress <= this.progress && !reset) return

    this.progressTarget.setAttribute('aria-valuenow', progress)
    const barElement = this.progressTarget.querySelector('.progress-bar')
    barElement.style.width = `${progress}%`
    this.progress = progress
  }

  setBasePath (basePath) {
    this.basePath = basePath
    this.folderAlertTextTarget.textContent = `Files will be uploaded to ${basePath} folder.`
    this.folderAlertTarget.classList.remove('d-none')
    this.element.scrollIntoView()
    this.element.focus()
  }

  clearBasePath () {
    this.basePath = null
    this.folderAlertTarget.classList.add('d-none')
  }

  // The dropzone is disabled by its radio button not being selected (radio:disable) and by other actions
  // being in progress (disable-actions:disable). Each disabler is tracked separately, so that the dropzone
  // is enabled only once none apply.
  disable (event) {
    // Disabling cancels uploads, so the dropzone isn't disabled while uploading (e.g., by disable-actions
    // disabling actions because of this upload).
    if (this.dropzone.getUploadingFiles().length > 0) return

    this.disablers.add(this.disablerFor(event))
    this.updateDisabled()
  }

  enable (event) {
    this.disablers.delete(this.disablerFor(event))
    this.updateDisabled()
  }

  // The identifier of the controller that dispatched the event (e.g., 'radio' for radio:disable), since
  // Stimulus prefixes dispatched events with the dispatching controller's identifier.
  disablerFor (event) {
    return event.type.split(':')[0]
  }

  updateDisabled () {
    const disabled = this.disablers.size > 0
    // Enabling an enabled dropzone would add its event listeners again.
    if (disabled === this.disabled) return

    this.disabled = disabled
    this.element.classList.toggle('opacity-50', disabled)
    if (disabled) {
      this.dropzone.disable()
    } else {
      this.dropzone.enable()
    }
    this.element.dataset.dropzoneReady = !disabled
  }
}
