# frozen_string_literal: true

def find_item_results_section
  find('section[aria-label="Item, collection, and APO results"]')
end

def find_project_results_section
  find('section[aria-label="Project results"]')
end

def find_tag_results_section
  find('section[aria-label="Tag results"]')
end

def find_ticket_results_section
  find('section[aria-label="Ticket results"]')
end

def find_pagination(brief: false)
  if brief
    find('nav.pagination')
  else
    find('nav.paginate-section')
  end
end

def find_next_page(brief: false)
  pagination_section = find_pagination(brief:)
  pagination_section.find_link('Next »')
end

def find_previous_page(brief: false)
  pagination_section = find_pagination(brief:)
  pagination_section.find_link('« Previous')
end

def find_project_result(project)
  find("li#projects-result-#{project.parameterize}")
end

def find_tag_result(tag)
  find("li#tags-result-#{tag.parameterize}")
end

def find_ticket_result(ticket)
  find("li#tickets-result-#{ticket.parameterize}")
end

def find_facet_section(facet_label)
  find("section[aria-label='#{facet_label}']")
end

def find_current_filters_section
  find('section[aria-label="Current Filters"]')
end

def find_current_filter(label, value)
  expected_text = if value
                    /#{label}\s+❯\s+#{value}/
                  else
                    label
                  end
  find_current_filters_section.find('li', text: expected_text)
end

def find_facet_toggle(facet_value, facet_label:)
  context = facet_label ? find_facet_section(facet_label) : page
  context.find_link("Toggle #{facet_value}")
end

def find_facet_more_link(facet_label)
  find_facet_section(facet_label).find_link('More')
end

def find_search_field
  # This matches the search field in header.
  find_field('Search for')
end

def find_object_type_field
  find_field('Select object type')
end
