# frozen_string_literal: true

# Controller for managing mounted content
class ContentMountController < ContentsApplicationController
  include FileDiscoveryConcern

  skip_verify_authorized only: %i[show new create]

  def new
    @mount_form = MountForm.new
    @files_discovered = params[:files_discovered] == 'true' # Triggers a reload of files section.

    render layout: false
  end

  def create
    @mount_form = MountForm.new(mount_form_params)
    if @mount_form.valid?
      @content.discovery_started!
      DiscoverFilesJob.perform_later(content: @content, mount_path: @mount_form.path)
      redirect_to content_mount_path(@content_token, discovery_started: true)
    else
      render :new, layout: false, status: :unprocessable_content
    end
  end

  private

  def mount_form_params
    MountForm.params_from(params)
  end

  def discovery_frame_name
    'mount'
  end

  def new_discovery_path(...)
    new_content_mount_path(@content_token, ...)
  end
end
