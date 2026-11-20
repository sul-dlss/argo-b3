import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'

// Visits a URL on an event (e.g., change->visit#visit on a checkbox with data-visit-url-param).
export default class extends Controller {
  visit ({ params: { url } }) {
    Turbo.visit(url)
  }
}
