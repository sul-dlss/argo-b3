# frozen_string_literal: true

# Component for rendering the application header
class HeaderComponent < ApplicationComponent
  def logged_in_text
    "Logged in as #{Current.user.name}"
  end
end
