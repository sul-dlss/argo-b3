// A choice container's own elements, as opposed to the content shown for that choice.
// Mark content with choice-always-shown to show it even when the choice is not selected.
const CHOICE_OWN_ELEMENTS = 'label.form-check-label, .invalid-feedback, div:has(> .form-text), .choice-always-shown'

// Hides unavailable fields as well as disabling them, since a disabled field alone was not obviously unavailable.
// Disabling keeps the fields out of the submitted params without changing their values.
export function setFieldsAvailable (element, available) {
  element.classList.toggle('d-none', !available)
  // A disabled fieldset disables everything inside it.
  if ('disabled' in element) {
    element.disabled = !available
  } else {
    element.querySelectorAll('input, select, textarea').forEach((input) => { input.disabled = !available })
  }
}

// The content that a radio button or checkbox's container (e.g., RadioButtonComponent) renders for that choice,
// i.e., all of its children but the input and its own label, help text and errors.
export function choiceContent (input) {
  const container = input.closest('.form-check')
  return Array.from(container.children).filter((child) => child !== input && !child.matches(CHOICE_OWN_ELEMENTS))
}
