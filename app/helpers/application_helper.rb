# frozen_string_literal: true

module ApplicationHelper
  def facet_label(form_field)
    I18n.t("search.facets.#{form_field}", default: form_field.to_s.humanize)
  end

  def facet_id(form_field)
    "#{form_field.to_s.dasherize}-facet"
  end
end
