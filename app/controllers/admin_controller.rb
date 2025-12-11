# frozen_string_literal: true

# Controller for admin-related actions
class AdminController < ApplicationController
  def groups
    authorize! :groups?, with: AdminPolicy
  end
end
