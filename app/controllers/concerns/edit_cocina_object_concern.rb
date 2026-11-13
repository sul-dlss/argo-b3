# frozen_string_literal: true

# Concern for a controller whose edit and update actions edit a Cocina object with an EditCocinaObjectFormConcern form.
# Includers declare the form with edit_form and define set_edit_view; messages are under edit.<controller>.edit.
module EditCocinaObjectConcern
  extend ActiveSupport::Concern

  included do
    class_attribute :edit_form_class, instance_writer: false
    before_action :set_druid_and_cocina_object, only: %i[edit update] # rubocop:disable Rails/LexicallyScopedActionFilter
  end

  class_methods do
    # @param form_class [Class] the form, which includes EditCocinaObjectFormConcern and LockFormConcern
    def edit_form(form_class)
      self.edit_form_class = form_class
    end
  end

  private

  def set_druid_and_cocina_object
    @druid = params[:id]
    @cocina_object = Sdr::Repository.find(druid: @druid)
  end

  def version_service
    @version_service ||= Sdr::VersionService.new(druid: @druid)
  end

  # @return [EditCocinaObjectFormConcern] the form for the edit page
  def prefilled_edit_form
    edit_form_class.for_edit(@cocina_object, version_service:)
  end

  # @return [EditCocinaObjectFormConcern] the form with the submitted changes
  def submitted_edit_form
    edit_form_class.from_submission(@cocina_object, version_service:, params: edit_form_class.params_from(params))
  end

  def redirect_not_editable
    redirect_to object_path(@druid), flash: { danger: edit_warning(:not_editable) }
  end

  def redirect_stale
    redirect_to url_for(action: :edit, id: @druid), flash: { danger: edit_warning(:stale) }
  end

  # For objects with files, whose mutable Content cannot follow the object to its new lock while it is busy.
  def redirect_content_busy
    redirect_to url_for(action: :edit, id: @druid), flash: { danger: edit_warning(:content_busy) }
  end

  # For objects with files, which can't be deposited while assembly is stopped with a process in error.
  def redirect_assembly_stopped_with_error
    redirect_to object_path(@druid), flash: { warning: edit_warning(:assembly_stopped_with_error) }
  end

  def render_invalid_edit
    set_edit_view
    render :edit, status: :unprocessable_content
  end

  def edit_warning(key)
    t("edit.#{controller_name}.edit.warnings.#{key}")
  end
end
