import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  load (event) {
    const collapseControl = event.target
    const turboFrame = document.querySelector(`${collapseControl.getAttribute('href')} turbo-frame`)
    turboFrame.setAttribute('loading', 'eager')
  }
}
