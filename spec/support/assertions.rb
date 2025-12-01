# frozen_string_literal: true

def assert_home_page
  # Cyperful sets page title to "Cyperful"
  expect(page).to have_title('Home page') unless ENV['CYPERFUL']
end

def assert_item_search_page
  # Cyperful sets page title to "Cyperful"
  expect(page).to have_title('Items search page') unless ENV['CYPERFUL']
end
