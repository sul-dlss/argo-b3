# frozen_string_literal: true

module ApplicationHelper
  def facet_label(form_field)
    I18n.t("search.facets.#{form_field}", default: form_field.to_s.humanize)
  end
end
