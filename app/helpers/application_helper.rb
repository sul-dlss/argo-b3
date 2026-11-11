# frozen_string_literal: true

module ApplicationHelper
  # Sets the page title (the layout appends the product name); name identifies the object or record when the h1 doesn't.
  def page_title(text, name: nil)
    content_for(:title, [text, name.presence].compact.join(' – '))
  end

  def document_title
    product_name = t('layouts.application.product_name')
    content_for?(:title) ? safe_join([content_for(:title), product_name], ' | ') : product_name
  end

  def facet_label(form_field)
    I18n.t("search.facets.#{form_field}", default: form_field.to_s.humanize.singularize)
  end

  def facet_id(form_field, suffix: nil)
    parts = [form_field.to_s.dasherize, 'facet']
    parts << suffix.to_s if suffix.present?
    parts.join('-')
  end

  def facet_value_label(value)
    I18n.t("search.facet_values.#{value}", default: value.to_s.humanize)
  end

  def format_datetime(datetime, format: :date_time)
    return if datetime.blank?

    I18n.l(datetime.in_time_zone(Constants::TIME_ZONE), format:)
  end

  def format_hash(hash, compact: true, pretty: true)
    formatted_hash = compact ? CocinaDisplay::Utils.deep_compact_blank(hash) : hash
    if pretty
      JSON.pretty_generate(formatted_hash)
    else
      JSON.generate(formatted_hash)
    end
  end
end
