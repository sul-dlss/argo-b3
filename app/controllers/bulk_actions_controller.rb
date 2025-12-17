# frozen_string_literal: true

# Controller for bulk actions.
class BulkActionsController < ApplicationController
  # Listing actions don't require authorization.
  skip_verify_authorized only: [:new]

  def new; end
end
