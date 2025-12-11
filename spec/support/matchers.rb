# frozen_string_literal: true

RSpec::Matchers.define :have_toast do |text, **args|
  match do |actual|
    actual.has_css?('.toast-container .toast', text:, **args)
  end
end

RSpec::Matchers.define :have_invalid_feedback do |field_selector, text, **args|
  match do |actual|
    actual.find_field(field_selector).sibling('.invalid-feedback', text:, **args)
  end
end

RSpec::Matchers.define :matching_form do |expected_form|
  match do |actual|
    actual[:search_form].attributes == expected_form.attributes
  end
end
