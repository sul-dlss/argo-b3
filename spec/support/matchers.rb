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

RSpec::Matchers.define :be_unauthorized do
  match do |_actual|
    expect(response).to redirect_to(root_path)
    follow_redirect!
    response.body.include?('You are not authorized to perform the requested action.')
  end
end
