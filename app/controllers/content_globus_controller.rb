# frozen_string_literal: true

# Controller for managing content transferred to Globus
class ContentGlobusController < ContentsApplicationController
  include FileDiscoveryConcern

  skip_verify_authorized only: %i[new create discover]
  before_action :set_globus_directory, only: %i[new create discover]

  def new
    @directory_writable = @globus_directory.writable?

    render layout: false
  end

  # Creates the user's Globus directory for the object.
  def create
    if @globus_directory.create
      redirect_to new_content_globus_path(@content_token)
    else
      @error = t('edit.contents.globus.errors.create_failed')
      @directory_writable = false
      render :new, layout: false, status: :unprocessable_content
    end
  end

  def discover
    start_discovery(file_location: :globus, mount_path: @globus_directory.local_path)
  end

  private

  def set_globus_directory
    @globus_directory = GlobusDirectory.for_object(druid: @content.druid, user: current_user)
  end
end
