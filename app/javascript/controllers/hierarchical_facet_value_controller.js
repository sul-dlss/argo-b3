import { Controller } from '@hotwired/stimulus'

// Changes a turbo-frame to eager loading when its parent collapse control is activated.
export default class extends Controller {
  load (event) {
    const collapseControl = event.target
    const turboFrame = document.querySelector(`${collapseControl.getAttribute('href')} turbo-frame`)
    turboFrame.setAttribute('loading', 'eager')
  }
}
