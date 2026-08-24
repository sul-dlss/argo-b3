# frozen_string_literal: true

# Controller for updating a single object's embargo release date.
class EmbargoesController < ApplicationController
  UPDATE_DESCRIPTION = 'Updated embargo release date'

  before_action :set_embargo_form

  def edit; end

  def update
    @embargo_form.embargo_release_date = embargo_form_params[:embargo_release_date]

    if @embargo_form.valid?
      update_embargo
      flash[:toast] = 'Embargo release date updated.'
      redirect_to object_path(@embargo_form.druid)
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_embargo_form
    druid = params.expect(:object_druid)
    cocina_object = Sdr::Repository.find(druid:)
    authorize! cocina_object, to: :edit?, with: ObjectPolicy

    unless cocina_object.dro? && cocina_object.access.embargo.present?
      raise Sdr::Repository::NotFoundResponse, "Embargo not found: #{druid}"
    end

    @embargo_form = EmbargoForm.build_from_cocina_object(cocina_object)
  end

  def embargo_form_params
    params.expect(embargo: [:embargo_release_date])
  end

  def update_embargo
    return unless @embargo_form.changed?

    open_new_version_if_needed
    @embargo_form.save!(user_name: current_user.sunetid, description: UPDATE_DESCRIPTION)
  end

  def open_new_version_if_needed
    return if Sdr::VersionService.open?(druid: @embargo_form.druid)

    unless Sdr::VersionService.openable?(druid: @embargo_form.druid)
      raise Sdr::Repository::Error, 'Unable to open new version'
    end

    release_date = @embargo_form.embargo_release_date
    cocina_object = Sdr::VersionService.open(druid: @embargo_form.druid,
                                             description: UPDATE_DESCRIPTION,
                                             opening_user_name: current_user.sunetid)
    @embargo_form = EmbargoForm.build_from_cocina_object(cocina_object)
    @embargo_form.embargo_release_date = release_date
  end
end
