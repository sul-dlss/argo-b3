// Whether a morph should leave this element's attributes alone, so a collapsible section
// (CollapsibleSectionComponent) keeps the expanded or collapsed state the user chose.
export function isCollapsibleSectionState (element) {
  return element.matches('.collapsible-section-toggle, .collapsible-section > .collapse')
}
