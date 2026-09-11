# frozen_string_literal: true

# Component for rendering the application header
class HeaderComponent < ApplicationComponent
  def logged_in_text
    "Logged in as #{Current.user.name}"
  end

  def admin?
    helpers.allowed_to?(:admin?, nil, with: AdminPolicy)
  end

  def show_impersonation_link?
    return true if impersonating?

    helpers.allowed_to?(:impersonate?, nil, with: AdminPolicy)
  end

  delegate :impersonating?, to: :Current

  def register_item?
    helpers.allowed_to?(:new?, nil, with: ItemPolicy)
  end
end
