import { Controller } from '@hotwired/stimulus'

// Applies a facet search after the user selects a value.
export default class extends Controller {
  submit (event) {
    event.target.form.requestSubmit()
  }
}
