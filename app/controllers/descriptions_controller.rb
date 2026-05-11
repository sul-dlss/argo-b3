# frozen_string_literal: true

# Controller for editing the descriptive metadata of an object.
class DescriptionsController < ApplicationController
  before_action :load_cocina_object

  def edit
    authorize! @cocina_object, with: ObjectPolicy, to: :edit_description?
    open_version_if_needed!
  rescue Sdr::Repository::Error
    # If pre-opening fails, save will attempt it again
  end

  def update
    authorize! @cocina_object, with: ObjectPolicy, to: :edit_description?

    new_description = build_description
    validate_result = CocinaSupport.validate(@cocina_object, description: new_description)

    if validate_result.failure?
      flash.now[:warning] = validate_result.failure
      render :edit, status: :unprocessable_content
      return
    end

    save_description!(new_description)
  rescue Sdr::Repository::Error => e
    flash.now[:warning] = e.message
    render :edit, status: :unprocessable_content
  end

  private

  def load_cocina_object
    @cocina_object = Sdr::Repository.find(druid: params.expect(:object_druid))
  rescue Sdr::Repository::NotFoundResponse
    redirect_to root_path, flash: { warning: 'Object not found.' }
  end

  def open_version_if_needed!
    return if Sdr::VersionService.open?(druid: @cocina_object.externalIdentifier)

    Sdr::VersionService.open(druid: @cocina_object.externalIdentifier,
                             description: 'Descriptive metadata edited via web form',
                             opening_user_name: current_user.sunetid)
  rescue Dor::Services::Client::Error => e
    raise Sdr::Repository::Error, "Opening version failed: #{e.message}"
  end

  def close_version!
    druid = @cocina_object.externalIdentifier
    Sdr::VersionService.close(druid:) if Sdr::VersionService.closeable?(druid:)
  rescue Dor::Services::Client::Error => e
    raise Sdr::Repository::Error, "Closing version failed: #{e.message}"
  end

  def save_description!(new_description)
    open_version_if_needed!
    updated_object = @cocina_object.new(description: new_description)
    Sdr::Repository.update(cocina_object: updated_object,
                           user_name: current_user.sunetid,
                           description: 'Descriptive metadata edited via web form')
    close_version!
    redirect_to object_path(druid: @cocina_object.externalIdentifier), flash: { success: 'Description updated.' }
  end

  def build_description
    DescriptionBuilder.new(existing_description: @cocina_object.description.to_h)
                      .build(description_params)
  end

  # rubocop:disable Rails/StrongParametersExpect
  def description_params
    params.require(:description).permit(
      title: [:value, :type, :_raw_json, :_original, { struct_parts: %i[value type] }],
      note: %i[value type],
      language: %i[code value],
      contributor: %i[_raw_json _original name_value life_dates type primary role_value],
      subject: [:_raw_json, :value, :type, :source_code, :_struct_original, { struct_parts: %i[value type] }],
      form: %i[_raw_json value type source_code],
      event: %i[_raw_json _original date_value type place_value publisher_value],
      related_resource: %i[_raw_json title_value type url],
      access: { physical_location: %i[value type], access_contact: %i[value type] }
    ).to_h.deep_symbolize_keys
  end
  # rubocop:enable Rails/StrongParametersExpect
end
