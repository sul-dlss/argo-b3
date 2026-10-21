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

  def can_register_item?
    helpers.allowed_to?(:new?, nil, with: ItemPolicy)
  end

  # @return [Boolean]
  def can_register_collection?
    helpers.allowed_to?(:new?, nil, with: CollectionPolicy)
  end

  def can_register_apo?
    helpers.allowed_to?(:new?, nil, with: ApoPolicy)
  end

  def can_register_agreement?
    helpers.allowed_to?(:new?, nil, with: AgreementPolicy)
  end
end
