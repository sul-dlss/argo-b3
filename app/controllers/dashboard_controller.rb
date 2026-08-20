# frozen_string_literal: true

# Controller for the dashboard (root page)
class DashboardController < ApplicationController
  skip_verify_authorized only: %i[index go_to_druid]

  def index
    @go_to_druid_form = GoToDruidForm.new
  end

  def go_to_druid
    @go_to_druid_form = GoToDruidForm.new(params.expect(go_to_druid: [:druid]))

    if @go_to_druid_form.valid?
      redirect_to object_path(@go_to_druid_form.druid)
    else
      render :index, status: :unprocessable_content
    end
  end
end
