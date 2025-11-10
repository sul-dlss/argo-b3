# frozen_string_literal: true

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component
  config.include ViewComponent::SystemSpecHelpers, type: :system
end
