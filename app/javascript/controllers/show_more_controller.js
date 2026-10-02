import { Controller } from '@hotwired/stimulus'

// Reveal results that are hidden on initial render, then remove the "More" link.
// Mark the hidden results with:
//   <li data-show-more-target="hidden" class="d-none"></li>
// Mark the link with:
//   <button data-show-more-target="link" data-action="show-more#showAll"></button>
export default class extends Controller {
  static targets = ['hidden', 'link']

  showAll () {
    this.hiddenTargets.forEach((result) => result.classList.remove('d-none'))
    this.linkTarget.remove()
  }
}
