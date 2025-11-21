# frozen_string_literal: true

module ApplicationHelper
  def facet_label(form_field)
    I18n.t("search.facets.#{form_field}", default: form_field.to_s.humanize)
  end

  def facet_id(form_field, suffix: nil)
    parts = [form_field.to_s.dasherize, 'facet']
    parts << suffix.to_s if suffix.present?
    parts.join('-')
  end
end
