# frozen_string_literal: true

# Controller for editing the descriptive metadata of an object.
class DescriptionsController < ApplicationController
  before_action :load_cocina_object

  FIELD_RESULT_KEY = {
    'title' => :title, 'note' => :note, 'language' => :language,
    'contributor' => :contributor, 'subject' => :subject, 'form' => :form,
    'event' => :event, 'related_resource' => :relatedResource
  }.freeze

  FIELD_MODEL_CLASS = {
    'title' => Cocina::Models::Title,
    'note' => Cocina::Models::DescriptiveValue,
    'language' => Cocina::Models::Language,
    'contributor' => Cocina::Models::Contributor,
    'subject' => Cocina::Models::DescriptiveValue,
    'form' => Cocina::Models::DescriptiveValue,
    'event' => Cocina::Models::Event,
    'related_resource' => Cocina::Models::RelatedResource
  }.freeze

  def edit
    authorize! @cocina_object, with: ObjectPolicy, to: :edit_description?
    open_version_if_needed!
  rescue Sdr::Repository::Error
    # If pre-opening fails, save will attempt it again
  end

  # rubocop:disable Metrics/AbcSize
  def field_json
    authorize! @cocina_object, with: ObjectPolicy, to: :edit_description?

    result_key = FIELD_RESULT_KEY[params.require(:field_type)]
    return head :bad_request unless result_key

    built = DescriptionBuilder.new(existing_description: {}).build(description_params)
    item = built[result_key]&.first
    return head(:unprocessable_content) unless item

    render json: FIELD_MODEL_CLASS[params[:field_type]].new(item).to_h
  rescue ActionController::ParameterMissing, JSON::ParserError,
         Cocina::Models::ValidationError, Dry::Struct::Error
    head :unprocessable_content
  end
  # rubocop:enable Metrics/AbcSize

  def render_field
    authorize! @cocina_object, with: ObjectPolicy, to: :edit_description?

    data = JSON.parse(params.require(:json)).deep_symbolize_keys
    result = field_partial_config(params.require(:field_type), data)
    return head :bad_request unless result

    render partial: result[:partial], locals: result[:locals]
  rescue JSON::ParserError, Cocina::Models::ValidationError, Dry::Struct::Error
    head :unprocessable_content
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

  # rubocop:disable Metrics/CyclomaticComplexity
  def field_partial_config(field_type, data)
    case field_type
    when 'title'       then { partial: 'descriptions/title_fields',
                              locals: { title: Cocina::Models::Title.new(data) } }
    when 'note'        then { partial: 'descriptions/note_fields',
                              locals: { note: Cocina::Models::DescriptiveValue.new(data) } }
    when 'language'    then { partial: 'descriptions/language_fields',
                              locals: { language: Cocina::Models::Language.new(data) } }
    when 'contributor' then { partial: 'descriptions/contributor_fields', locals: { contributor: data } }
    when 'subject'     then { partial: 'descriptions/subject_fields',     locals: { subject: data } }
    when 'form'        then { partial: 'descriptions/form_fields',         locals: { form: data } }
    when 'event'       then { partial: 'descriptions/event_fields',        locals: { event: data } }
    when 'related_resource' then { partial: 'descriptions/related_resource_fields',
                                   locals: { related_resource: data } }
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def build_description
    DescriptionBuilder.new(existing_description: @cocina_object.description.to_h)
                      .build(description_params)
  end

  # rubocop:disable Rails/StrongParametersExpect
  def description_params
    params.require(:description).permit(
      title: [:value, :type, :_raw_json, :_original, { struct_parts: %i[value type] }],
      note: %i[value type _raw_json],
      language: %i[code value _raw_json],
      contributor: %i[_raw_json _original name_value life_dates type primary role_value],
      subject: [:_raw_json, :value, :type, :source_code, :_struct_original, { struct_parts: %i[value type] }],
      form: %i[_raw_json value type source_code],
      event: %i[_raw_json _original date_value date_start_value date_end_value type place_value publisher_value],
      related_resource: %i[_raw_json title_value type url],
      access: { physical_location: %i[value type], access_contact: %i[value type] }
    ).to_h.deep_symbolize_keys
  end
  # rubocop:enable Rails/StrongParametersExpect
end
