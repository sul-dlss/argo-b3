# frozen_string_literal: true

# Controller for showing and editing a file set (resource) of a content
class ContentFileSetsController < ContentsApplicationController
  # Authorization is coming from the verified content_id token.
  skip_verify_authorized only: %i[update edit show destroy]
  before_action :set_content_file_set
  before_action :set_counter, except: :destroy

  def show
    @files_deleted = params[:files_deleted] == 'true' # Triggers a reload of files sections.
  end

  def edit
    @content_file_set_form = ContentFileSetForm.from_model(@content_file_set)
  end

  def update
    @content_file_set_form = ContentFileSetForm.from_model(@content_file_set)
    @content_file_set_form.assign_attributes(content_file_set_params)
    if !@content_file_set_form.save
      render :edit, status: :unprocessable_content
    elsif @content_file_set_form.content_file_set_destroyed?
      render_destroyed
    else
      redirect_to_show
    end
  end

  def destroy
    ContentFileSetForm.from_model(@content_file_set).destroy
    render_destroyed
  end

  private

  # The resource no longer exists, so the files sections (including the structure) are reloaded.
  def render_destroyed
    flash.now[:toast] = t('edit.content_file_sets.toasts.deleted')
    render :destroyed, formats: :turbo_stream
  end

  def redirect_to_show
    flash[:toast] = t('edit.content_file_sets.toasts.updated')
    # Deleted binaries are no longer in the files sections, so tell show to reload the files section.
    files_deleted = @content_file_set_form.content_file_binaries_destroyed?.presence
    redirect_to content_content_file_set_path(@content_token, @content_file_set, counter: @counter, files_deleted:)
  end

  def set_content_file_set
    @content_token = params[:content_id]
    verified_content_id = verify_token(@content_token)
    @content_file_set = ContentFileSet.find(params.expect(:id))
    forbidden_access if @content_file_set.content_id != verified_content_id
  end

  def set_counter
    @counter = params.expect(:counter).to_i
  end

  def content_file_set_params
    params.permit(content_file_set: ContentFileSetForm.permitted_params)[:content_file_set]
  end
end
