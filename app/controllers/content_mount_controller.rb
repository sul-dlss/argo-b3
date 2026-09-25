# frozen_string_literal: true

# Controller for managing mounted content
class ContentMountController < ContentsApplicationController
  before_action :set_content
  skip_verify_authorized only: %i[show new create]

  def show
    if @content.discovery_not_in_progress?
      flash[:toast] = t('edit.contents.mount.toasts.discovery_completed')
      redirect_to new_content_mount_path(@content_token, files_discovered: true)
    else
      render layout: false
    end
  end

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
      redirect_to content_mount_path(@content_token)
    else
      render :new, layout: false, status: :unprocessable_content
    end
  end

  private

  def mount_form_params
    params.expect(mount: MountForm.permitted_params)
  end

  def set_content
    @content_token = params[:content_id]
    verified_content_id = verify_token(@content_token)
    @content = Content.find(verified_content_id)
  end
end
