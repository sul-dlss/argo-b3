# frozen_string_literal: true

# Controller for managing mounted content
class ContentMountController < ContentsApplicationController
  include FileDiscoveryConcern

  skip_verify_authorized only: %i[new create]

  def new
    @mount_form = MountForm.new

    render layout: false
  end

  def create
    @mount_form = MountForm.new(mount_form_params)
    if @mount_form.valid?
      start_discovery(mount_path: @mount_form.path)
    else
      render :new, layout: false, status: :unprocessable_content
    end
  end

  private

  def mount_form_params
    MountForm.params_from(params)
  end
end
