# frozen_string_literal: true

# Controller for editing the descriptive metadata of an object.
class DescriptionsController < ApplicationController
  before_action :load_cocina_object

  def edit
    authorize! @cocina_object, with: ObjectPolicy, to: :edit_description?
  end

  def update
    authorize! @cocina_object, with: ObjectPolicy, to: :edit_description?

    new_description = build_description
    validate_result = CocinaSupport.validate(@cocina_object, description: new_description)

    if validate_result.failure?
      flash.now[:warning] = validate_result.failure
      render :edit, status: :unprocessable_entity
      return
    end

    open_version_if_needed!
    updated_object = @cocina_object.new(description: new_description)
    Sdr::Repository.update(cocina_object: updated_object,
                           user_name: current_user.sunetid,
                           description: 'Descriptive metadata edited via web form')
    close_version!
    redirect_to object_path(druid: @cocina_object.externalIdentifier), flash: { success: 'Description updated.' }
  rescue Sdr::Repository::Error => e
    flash.now[:warning] = e.message
    render :edit, status: :unprocessable_entity
  end

  private

  def load_cocina_object
    @cocina_object = Sdr::Repository.find(druid: params[:object_druid])
  rescue Sdr::Repository::NotFoundResponse
    redirect_to root_path, flash: { warning: 'Object not found.' }
  end

  def open_version_if_needed!
    return if Sdr::VersionService.open?(druid: @cocina_object.externalIdentifier)

    Sdr::VersionService.open(druid: @cocina_object.externalIdentifier,
                             description: 'Descriptive metadata edited via web form',
                             opening_user_name: current_user.sunetid)
  end

  def close_version!
    druid = @cocina_object.externalIdentifier
    Sdr::VersionService.close(druid:) if Sdr::VersionService.closeable?(druid:)
  end

  # Merges submitted fields into the existing description, preserving fields
  # not yet exposed by this editor (events, form, etc.).
  def build_description
    existing = @cocina_object.description.to_h
    submitted = description_params

    titles = submitted[:title]&.filter_map { |t| build_title(t) }
    notes = submitted[:note]&.filter_map { |n| compact_entry(n, required: :value) }
    languages = submitted[:language]&.filter_map { |l| compact_entry(l, required: :code) }
    contributors = submitted[:contributor]&.filter_map { |c| build_contributor(c) }
    subjects = submitted[:subject]&.filter_map { |s| build_subject(s) }
    forms = submitted[:form]&.filter_map { |f| build_form(f) }
    events = submitted[:event]&.filter_map { |e| build_event(e) }
    related_resources = submitted[:related_resource]&.filter_map { |r| build_related_resource(r) }
    access = build_access(submitted[:access])

    existing.merge(
      title: titles.presence || existing[:title],
      note: notes.presence || existing[:note],
      language: languages.presence || existing[:language],
      contributor: contributors.presence || existing[:contributor],
      subject: subjects.presence || existing[:subject],
      form: forms.presence || existing[:form],
      event: events.presence || existing[:event],
      relatedResource: related_resources.presence || existing[:relatedResource],
      access: access || existing[:access]
    ).compact
  end

  # Reconstructs a contributor hash from either raw JSON or curated form fields.
  # Uses _original as a base to preserve role codes/URIs not exposed in the form.
  def build_title(params)
    return safe_parse_json(params[:_raw_json]) if params[:_raw_json].present?

    if params[:struct_parts].present?
      base = params[:_original].present? ? (safe_parse_json(params[:_original]) || {}) : {}
      parts = params[:struct_parts].filter_map { |p| compact_entry(p, required: :value) }
      return nil if parts.empty?

      result = base.merge(structuredValue: parts)
      params[:type].present? ? result[:type] = params[:type] : result.delete(:type)
      result
    else
      compact_entry({ value: params[:value], type: params[:type] }, required: :value)
    end
  end

  def build_contributor(params)
    return safe_parse_json(params[:_raw_json]) if params[:_raw_json].present?
    return nil if params[:name_value].blank?

    base = params[:_original].present? ? safe_parse_json(params[:_original]) : {}
    return nil if base.nil?

    name_entry = if params[:life_dates].present?
                   { structuredValue: [{ value: params[:name_value], type: 'name' },
                                       { value: params[:life_dates], type: 'life dates' }] }
                 else
                   { value: params[:name_value] }
                 end

    result = base.merge(name: [name_entry])
    result[:type] = params[:type] if params[:type].present?

    if params[:primary] == '1'
      result[:status] = 'primary'
    else
      result.delete(:status)
    end

    # Update the first role's display value while preserving code/uri/source from _original.
    if params[:role_value].present?
      existing_role = base.dig(:role, 0) || {}
      result[:role] = [existing_role.merge(value: params[:role_value])]
    end

    result
  end

  # Reconstructs a subject hash from either raw JSON or curated form fields.
  def build_subject(params)
    return safe_parse_json(params[:_raw_json]) if params[:_raw_json].present?

    if params[:struct_parts].present?
      base = params[:_struct_original].present? ? (safe_parse_json(params[:_struct_original]) || {}) : {}
      parts = params[:struct_parts].filter_map { |p| compact_entry(p, required: :value) }
      return nil if parts.empty?

      base.merge(structuredValue: parts)
    else
      return nil if params[:value].blank?

      entry = { value: params[:value] }
      entry[:type] = params[:type] if params[:type].present?
      entry[:source] = { code: params[:source_code] } if params[:source_code].present?
      entry
    end
  end

  def build_form(params)
    return safe_parse_json(params[:_raw_json]) if params[:_raw_json].present?
    return nil if params[:value].blank?

    entry = { value: params[:value] }
    entry[:type] = params[:type] if params[:type].present?
    entry[:source] = { code: params[:source_code] } if params[:source_code].present?
    entry
  end

  def build_event(params)
    return safe_parse_json(params[:_raw_json]) if params[:_raw_json].present?
    return nil if params[:date_value].blank? && params[:type].blank?

    base = params[:_original].present? ? (safe_parse_json(params[:_original]) || {}) : {}
    result = base.dup

    params[:type].present? ? result[:type] = params[:type] : result.delete(:type)

    if params[:date_value].present?
      existing_date = base.dig(:date, 0) || {}
      result[:date] = [existing_date.merge(value: params[:date_value])]
    end

    if params[:place_value].present?
      # Preserve all original locations (e.g. value + MARC country code pair);
      # update only the first entry that has a value field.
      locs = base[:location]&.dup || []
      idx = locs.index { |l| l[:value].present? } || 0
      locs[idx] = (locs[idx] || {}).merge(value: params[:place_value])
      result[:location] = locs
    end

    if params[:publisher_value].present?
      existing_contributor = base.dig(:contributor, 0) || {}
      existing_name = existing_contributor.dig(:name, 0) || {}
      result[:contributor] = [existing_contributor.merge(
        type: existing_contributor[:type] || 'organization',
        name: [existing_name.merge(value: params[:publisher_value])],
        role: existing_contributor[:role].presence || [{ value: 'publisher' }]
      )]
    elsif base[:contributor].blank?
      result.delete(:contributor)
    end

    result
  end

  def build_related_resource(params)
    return safe_parse_json(params[:_raw_json]) if params[:_raw_json].present?
    return nil if params[:title_value].blank? && params[:url].blank?

    entry = {}
    entry[:type] = params[:type] if params[:type].present?
    entry[:title] = [{ value: params[:title_value] }] if params[:title_value].present?
    entry[:access] = { url: [{ value: params[:url] }] } if params[:url].present?
    entry
  end

  def build_access(params)
    return nil if params.blank?

    existing_access = @cocina_object.description.to_h.fetch(:access, {})
    physical_locations = params[:physical_location]&.filter_map { |pl| compact_entry(pl, required: :value) }
    access_contacts = params[:access_contact]&.filter_map { |ac| compact_entry(ac, required: :value) }

    existing_access.merge(
      physicalLocation: physical_locations.presence || existing_access[:physicalLocation],
      accessContact: access_contacts.presence || existing_access[:accessContact]
    ).compact.presence
  end

  def safe_parse_json(str)
    JSON.parse(str).deep_symbolize_keys
  rescue JSON::ParserError
    nil
  end

  # Returns nil if the required key is blank (dropping the item), otherwise
  # returns the hash with blank optional keys removed.
  def compact_entry(hash, required:)
    return nil if hash[required].blank?

    hash.reject { |_, v| v.blank? }
  end

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
end
