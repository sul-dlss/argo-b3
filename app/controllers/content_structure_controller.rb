# frozen_string_literal: true

# Controller for editing the structure of a content
class ContentStructureController < ContentsApplicationController
  STRUCTURE_VALUE = 'structure'
  APPEND_VALUE = 'append'

  skip_verify_authorized only: %i[edit update]
  before_action :set_content_and_cocina_object

  def edit
    @structure_changed = params[:structure_changed] == 'true' # Triggers a reload of the files section.
    # The selected content type, which may not have been saved yet.
    @content_type = params[:content_type]
    @populator_selection = Contents::PopulatorSelector.call(content: @content, cocina_object: @cocina_object,
                                                            content_type: @content_type)

    render layout: false
  end

  def update
    populator = find_populator
    if params[:commit] == APPEND_VALUE
      populator.append(content: @content, cocina_object: @cocina_object)
      flash[:toast] = t('edit.contents.structure.toasts.append')
    else
      populator.structure(content: @content, cocina_object: @cocina_object)
      flash[:toast] = t('edit.contents.structure.toasts.structure')
    end

    redirect_to edit_content_structure_path(@content_token, structure_changed: true,
                                                            content_type: params[:content_type].presence)
  end

  private

  def find_populator
    Contents::PopulatorSelector::POPULATORS_BY_NAME.fetch(params[:populator]) do
      raise ActionController::BadRequest, "Unknown populator: #{params[:populator]}"
    end
  end

  def set_content_and_cocina_object
    @content_token = params[:content_id]
    verified_content_id = verify_token(@content_token)
    @content = Content.with_structural_associations.find(verified_content_id)
    @cocina_object = fetch_cocina_object(druid: @content.druid, lock: @content.lock)
  end

  def fetch_cocina_object(druid:, lock:)
    cocina_hash = fetch_cocina_hash(druid:, lock:)
    CocinaSupport.build_from_cocina_hash(cocina_hash)
  end
end
