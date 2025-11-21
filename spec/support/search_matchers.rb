# frozen_string_literal: true

RSpec::Matchers.define :have_facet do |facet_label, expanded: nil, **args|
  match do |actual|
    actual.has_css?("section[aria-label='#{facet_label}']", **args) do |section|
      next true if expanded.nil?

      is_expanded = section.has_css?('.accordion-collapse.collapse.show')
      is_expanded == expanded
    end
  end
end

RSpec::Matchers.define :have_facet_value do |facet_value, facet:, count: nil, **args|
  match do |actual|
    # This handles both link-based and checkbox-based facet values.
    expected = count ? "#{facet_value} (#{count})" : facet_value
    actual.has_css?("section[aria-label='#{facet}'] li,label", text: expected, **args)
  end
end

RSpec::Matchers.define :have_selected_facet_value do |facet_value, facet:, **args|
  match do |actual|
    # This handles both link-based and checkbox-based facet values.
    return true if actual.has_css?("section[aria-label='#{facet}'] li", text: facet_value, **args) do |el|
      el.has_link?('Remove')
    end

    actual.has_field?(facet_value, checked: true, **args)
  end
end

RSpec::Matchers.define :have_item_result do |solr_doc, args = {}|
  match do |actual|
    actual.has_css?("li#item-result-#{solr_doc[Search::Fields::BARE_DRUID]}", **args)
  end
end

RSpec::Matchers.define :have_result_count do |expected_count, args = {}|
  match do |actual|
    actual.has_css?('h3', text: /.*\((#{expected_count}) found\)/, **args)
  end
end

RSpec::Matchers.define :have_next_page do |**args|
  match do |actual|
    actual.has_link?('Next page', **args)
  end
end

RSpec::Matchers.define :have_previous_page do |**args|
  match do |actual|
    actual.has_link?('Previous page', **args)
  end
end

RSpec::Matchers.define :have_results_pages do |expected_page, expected_total_pages, args = {}|
  match do |actual|
    actual.has_text?("Page #{expected_page} of #{expected_total_pages}", **args)
  end
end

RSpec::Matchers.define :have_current_filter do |expected_form_field_name, expected_value, args = {}|
  match do |actual|
    actual.has_css?('section[aria-label="Current Filters"] li',
                    text: "#{expected_form_field_name}: #{expected_value}",
                    **args)
  end
end
