# frozen_string_literal: true

# Controller for showing and editing a file set (resource) of a content
class ContentFileSetsController < ContentsApplicationController
  # Authorization is coming from the verified content_id token.
  skip_verify_authorized only: %i[update edit show destroy move]
  before_action :set_content_file_set
  before_action :set_counter, except: %i[destroy move]

  def show
    @structure_changed = params[:structure_changed] == 'true' # Triggers a reload of the structure validation.
  end

  def edit
    @content_file_set_form = ContentFileSetForm.from_model(@content_file_set)
  end

  def update
    return if refused_while_busy?(@content_file_set.content)

    @content_file_set_form = ContentFileSetForm.from_model(@content_file_set)
    @content_file_set_form.assign_attributes(content_file_set_params)
    if !@content_file_set_form.save
      render :edit, status: :unprocessable_content
    elsif @content_file_set_form.content_file_set_destroyed?
      # Other resources are renumbered, so the page is refreshed.
      render_page_refresh(toast: t('edit.content_file_sets.toasts.deleted'))
    else
      redirect_to_show
    end
  end

  def destroy
    return if refused_while_busy?(@content_file_set.content)

    ContentFileSetForm.from_model(@content_file_set).destroy
    redirect_to_structure(toast: t('edit.content_file_sets.toasts.deleted'))
  end

  def move
    return if refused_while_busy?(@content_file_set.content)

    direction = params.expect(:direction)
    return head :bad_request unless ContentFileSet::MOVE_DIRECTIONS.include?(direction)

    @content_file_set.move(direction)
    redirect_to_structure(toast: t('edit.content_file_sets.toasts.moved'))
  end

  private

  # Other resources are renumbered, so the whole structure step is morphed.
  def redirect_to_structure(toast:)
    redirect_to edit_content_path(@content_file_set.content.druid), status: :see_other, flash: { toast: }
  end

  def redirect_to_show
    flash[:toast] = t('edit.content_file_sets.toasts.updated')
    redirect_to content_content_file_set_path(@content_token, @content_file_set, counter: @counter,
                                                                                 structure_changed: true)
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
    ContentFileSetForm.params_from(params)
  end
end
