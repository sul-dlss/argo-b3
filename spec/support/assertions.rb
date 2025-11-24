def assert_home_page
  expect(page).to have_title('Home page')
end

def assert_item_search_page
  expect(page).to have_title('Items search page')
end
