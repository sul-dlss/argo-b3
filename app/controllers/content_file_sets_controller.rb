# frozen_string_literal: true

# Controller for showing and editing a file set (resource) of a content
class ContentFileSetsController < ContentsApplicationController
  # Authorization is coming from the verified content_id token.
  skip_verify_authorized only: %i[update edit show]
  before_action :set_content_file_set_and_counter

  def show; end

  def edit
    @content_file_set_form = ContentFileSetForm.from_model(@content_file_set)
  end

  def update
    @content_file_set_form = ContentFileSetForm.from_model(@content_file_set)
    @content_file_set_form.assign_attributes(content_file_set_params)
    if @content_file_set_form.save
      flash[:toast] = t('edit.content_file_sets.toasts.updated')
      redirect_to content_content_file_set_path(@content_token, @content_file_set, counter: @counter)
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_content_file_set_and_counter
    @content_token = params[:content_id]
    verified_content_id = verify_token(@content_token)
    @content_file_set = ContentFileSet.find(params.expect(:id))
    @counter = params.expect(:counter).to_i
    forbidden_access if @content_file_set.content_id != verified_content_id
  end

  def content_file_set_params
    params.permit(content_file_set: ContentFileSetForm.permitted_params)[:content_file_set]
  end
end
