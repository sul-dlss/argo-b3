# frozen_string_literal: true

def find_item_results_section
  all('section[aria-label="Item, collection, and admin policy results"]')&.first
end

def find_project_results_section
  all('section[aria-label="Project results"]')&.first
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

def find_facet_section(facet_label)
  find("section[aria-label='#{facet_label}']")
end

def find_current_filters_section
  find('section[aria-label="Current Filters"]')
end
