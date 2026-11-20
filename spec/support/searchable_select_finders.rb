# frozen_string_literal: true

# Helpers for driving searchable selects, which hide the underlying select element.
# See app/javascript/controllers/searchable_select_controller.js.

# Found by the field's label (e.g., "APO"), which Tom Select points at the input it renders for typing.
# That input is hidden until the control is opened, so it is found among all elements.
def find_searchable_select(label)
  field_id = find('label', text: /\A#{Regexp.escape(label)}\b/)[:for]
  find_by_id(field_id, visible: :all).ancestor('.ts-wrapper')
end

# Open the select and type the query, returning the select (whose dropdown then shows the matching options).
def search_searchable_select(query, from:)
  find_searchable_select(from).tap do |select|
    # After choosing an option the field keeps focus, and clicking it then would close it rather than open it.
    select.find('.ts-control').click unless select.matches_css?('.focus', wait: 0)
    # Typed into the focused input, since Tom Select moves it offscreen (until typing) while an option is chosen,
    # where Selenium won't type into it directly.
    select.find('.ts-control input:focus', visible: :all)
    send_keys(query)
  end
end

# Type the option's label, then click the matching option.
def select_searchable_option(option_label, from:)
  select = search_searchable_select(option_label, from:)
  select.find('.ts-dropdown .option', exact_text: option_label).click
  # Tom Select leaves the dropdown open when the option clicked was already chosen.
  send_keys(:escape) if select.matches_css?('.dropdown-active', wait: 0)
end
