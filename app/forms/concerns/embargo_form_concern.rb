# frozen_string_literal: true

# Concern for the with_embargo toggle used by forms that support setting an embargo.
module EmbargoFormConcern
  extend ActiveSupport::Concern

  included do
    attribute :with_embargo, :boolean
    validates :embargo_release_date, presence: true, if: -> { with_embargo }

    before_validation :nullify_embargo_access_rights, if: -> { with_embargo == false }
  end

  private

  # Call this from the form initializer to set the with_embargo toggle.
  # When with_embargo is not provided, e.g., when not initialized from form params,
  # it is derived from the embargo release date.
  def derive_with_embargo
    self.with_embargo = embargo_release_date.present? if with_embargo.nil?
  end

  def nullify_embargo_access_rights
    self.embargo_release_date = nil
    self.embargo_view = nil
    self.embargo_download = nil
    self.embargo_location = nil
  end
end
