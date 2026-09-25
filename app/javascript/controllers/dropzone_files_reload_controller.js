import { Controller } from '@hotwired/stimulus'

// Reload the files sections (dropzone-files outlets) when connected, e.g., after files have been discovered on a mount.
export default class extends Controller {
  static outlets = ['dropzone-files']

  dropzoneFilesOutletConnected (dropzoneFiles) {
    dropzoneFiles.reload()
  }
}
