# frozen_string_literal: true

# Controller for the dashboard (root page)
class DashboardController < ApplicationController
  skip_verify_authorized only: %i[index]

  def index; end
end
