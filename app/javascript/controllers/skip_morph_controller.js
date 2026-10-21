import { Controller } from '@hotwired/stimulus'

// Keeps the element (e.g., a form with Tom Select) as is when the page is refreshed by morphing.
export default class extends Controller {
  skip (event) {
    event.preventDefault()
  }
}
