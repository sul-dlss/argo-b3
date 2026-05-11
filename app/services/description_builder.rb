# frozen_string_literal: true

# Merges submitted form params into an existing Cocina description hash,
# preserving fields not yet exposed by the editor.
class DescriptionBuilder
  def initialize(existing_description:)
    @existing = existing_description
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def build(submitted)
    titles = submitted[:title]&.filter_map { |t| build_title(t) }
    notes = submitted[:note]&.filter_map { |n| compact_entry(n, required: :value) }
    languages = submitted[:language]&.filter_map { |l| compact_entry(l, required: :code) }
    contributors = submitted[:contributor]&.filter_map { |c| build_contributor(c) }
    subjects = submitted[:subject]&.filter_map { |s| build_subject(s) }
    forms = submitted[:form]&.filter_map { |f| build_form(f) }
    events = submitted[:event]&.filter_map { |e| build_event(e) }
    related_resources = submitted[:related_resource]&.filter_map { |r| build_related_resource(r) }
    access = build_access(submitted[:access])

    @existing.merge(
      title: titles.presence || @existing[:title],
      note: notes.presence || @existing[:note],
      language: languages.presence || @existing[:language],
      contributor: contributors.presence || @existing[:contributor],
      subject: subjects.presence || @existing[:subject],
      form: forms.presence || @existing[:form],
      event: events.presence || @existing[:event],
      relatedResource: related_resources.presence || @existing[:relatedResource],
      access: access || @existing[:access]
    ).compact
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  private

  def build_title(params)
    return safe_parse_json(params[:_raw_json]) if params[:_raw_json].present?

    if params[:struct_parts].present?
      build_structured_title(params)
    else
      compact_entry({ value: params[:value], type: params[:type] }, required: :value)
    end
  end

  def build_structured_title(params)
    base = params[:_original].present? ? (safe_parse_json(params[:_original]) || {}) : {}
    parts = params[:struct_parts].filter_map { |p| compact_entry(p, required: :value) }
    return nil if parts.empty?

    result = base.merge(structuredValue: parts)
    params[:type].present? ? result[:type] = params[:type] : result.delete(:type)
    result
  end

  # rubocop:disable Metrics/AbcSize
  def build_contributor(params)
    return safe_parse_json(params[:_raw_json]) if params[:_raw_json].present?
    return nil if params[:name_value].blank?

    base = params[:_original].present? ? safe_parse_json(params[:_original]) : {}
    return nil if base.nil?

    result = base.merge(name: [build_contributor_name(params)])
    result[:type] = params[:type] if params[:type].present?
    apply_contributor_status(result, params)
    apply_contributor_role(result, base, params)
    result
  end
  # rubocop:enable Metrics/AbcSize

  def build_contributor_name(params)
    if params[:life_dates].present?
      { structuredValue: [{ value: params[:name_value], type: 'name' },
                          { value: params[:life_dates], type: 'life dates' }] }
    else
      { value: params[:name_value] }
    end
  end

  def apply_contributor_status(result, params)
    if params[:primary] == '1'
      result[:status] = 'primary'
    else
      result.delete(:status)
    end
  end

  # Update the first role's display value while preserving code/uri/source from _original.
  def apply_contributor_role(result, base, params)
    return if params[:role_value].blank?

    existing_role = base.dig(:role, 0) || {}
    result[:role] = [existing_role.merge(value: params[:role_value])]
  end

  def build_subject(params)
    return safe_parse_json(params[:_raw_json]) if params[:_raw_json].present?

    if params[:struct_parts].present?
      build_structured_subject(params)
    else
      build_simple_subject(params)
    end
  end

  def build_structured_subject(params)
    base = params[:_struct_original].present? ? (safe_parse_json(params[:_struct_original]) || {}) : {}
    parts = params[:struct_parts].filter_map { |p| compact_entry(p, required: :value) }
    return nil if parts.empty?

    base.merge(structuredValue: parts)
  end

  def build_simple_subject(params)
    return nil if params[:value].blank?

    entry = { value: params[:value] }
    entry[:type] = params[:type] if params[:type].present?
    entry[:source] = { code: params[:source_code] } if params[:source_code].present?
    entry
  end

  def build_form(params)
    return safe_parse_json(params[:_raw_json]) if params[:_raw_json].present?
    return nil if params[:value].blank?

    entry = { value: params[:value] }
    entry[:type] = params[:type] if params[:type].present?
    entry[:source] = { code: params[:source_code] } if params[:source_code].present?
    entry
  end

  # rubocop:disable Metrics/AbcSize
  def build_event(params)
    return safe_parse_json(params[:_raw_json]) if params[:_raw_json].present?
    return nil if params[:date_value].blank? && params[:type].blank?

    base = params[:_original].present? ? (safe_parse_json(params[:_original]) || {}) : {}
    result = base.dup
    apply_event_type(result, params)
    apply_event_date(result, base, params)
    apply_event_location(result, base, params)
    apply_event_publisher(result, base, params)
    result
  end
  # rubocop:enable Metrics/AbcSize

  def apply_event_type(result, params)
    params[:type].present? ? result[:type] = params[:type] : result.delete(:type)
  end

  # rubocop:disable Metrics/AbcSize
  def apply_event_date(result, base, params)
    existing_date = base.dig(:date, 0) || {}

    if params[:date_start_value].present? || params[:date_end_value].present?
      structured = []
      structured << { value: params[:date_start_value], type: 'start' } if params[:date_start_value].present?
      structured << { value: params[:date_end_value], type: 'end' } if params[:date_end_value].present?
      result[:date] = [existing_date.merge(structuredValue: structured)]
    elsif params[:date_value].present?
      result[:date] = [existing_date.merge(value: params[:date_value])]
    end
  end
  # rubocop:enable Metrics/AbcSize

  def apply_event_location(result, base, params)
    return if params[:place_value].blank?

    # Preserve all original locations (e.g. value + MARC country code pair);
    # update only the first entry that has a value field.
    locs = base[:location]&.dup || []
    idx = locs.index { |l| l[:value].present? } || 0
    locs[idx] = (locs[idx] || {}).merge(value: params[:place_value])
    result[:location] = locs
  end

  def apply_event_publisher(result, base, params)
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
  end

  # rubocop:disable Metrics/AbcSize
  def build_related_resource(params)
    return safe_parse_json(params[:_raw_json]) if params[:_raw_json].present?
    return nil if params[:title_value].blank? && params[:url].blank?

    entry = {}
    entry[:type] = params[:type] if params[:type].present?
    entry[:title] = [{ value: params[:title_value] }] if params[:title_value].present?
    entry[:access] = { url: [{ value: params[:url] }] } if params[:url].present?
    entry
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def build_access(params)
    return nil if params.blank?

    existing_access = @existing.fetch(:access, {})
    physical_locations = params[:physical_location]&.filter_map { |pl| compact_entry(pl, required: :value) }
    access_contacts = params[:access_contact]&.filter_map { |ac| compact_entry(ac, required: :value) }

    existing_access.merge(
      physicalLocation: physical_locations.presence || existing_access[:physicalLocation],
      accessContact: access_contacts.presence || existing_access[:accessContact]
    ).compact.presence
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

  def safe_parse_json(str)
    JSON.parse(str).deep_symbolize_keys
  rescue JSON::ParserError
    nil
  end

  def compact_entry(hash, required:)
    return nil if hash[required].blank?

    hash.compact_blank
  end
end
