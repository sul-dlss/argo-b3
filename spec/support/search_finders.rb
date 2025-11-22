# frozen_string_literal: true

def find_item_results_section
  all('section[aria-label="Item, collection, and admin policy results"]')&.first
end

def find_project_results_section
  all('section[aria-label="Project results"]')&.first
end

def find_tag_results_section
  all('section[aria-label="Tag results"]')&.first
end

def find_next_page
  find_link('Next page')
end

def find_previous_page
  find_link('Previous page')
end

def find_project_result(project)
  find("li#projects-result-#{project.parameterize}")
end

def find_tag_result(tag)
  find("li#tags-result-#{tag.parameterize}")
end

def find_facet_section(facet_label)
  find("section[aria-label='#{facet_label}']")
end

def find_current_filters_section
  find('section[aria-label="Current Filters"]')
end

def find_current_filter(label, value)
  find_current_filters_section.find('li', text: "#{label}: #{value}")
end

def find_facet_toggle(facet_value, facet_label:)
  context = facet_label ? find_facet_section(facet_label) : page
  context.find_link('+', title: "Toggle #{facet_value}")
end

def find_facet_more_link(facet_label)
  find_facet_section(facet_label).find_link('More')
end
