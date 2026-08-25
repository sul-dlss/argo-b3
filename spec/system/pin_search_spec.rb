# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pin and unpin a search', :solr do
  before do
    create_list(:solr_item, 2)
    sign_in(create(:user))
  end

  it 'pins from the search page and unpins from the dashboard' do
    visit search_path(query: 'foo')

    expect(page).to have_button('Pin')

    click_button 'Pin'

    expect(page).to have_button('Unpin')
    expect(page).to have_no_button('Pin')
    expect(page).to have_text('Pin added')

    visit root_path

    expect(page).to have_link('"foo"')
    expect(page).to have_button('Unpin')

    click_button 'Unpin'

    expect(page).to have_no_link('"foo"')
    expect(page).to have_text('No searches have been pinned.')
    expect(page).to have_text('Pin removed')
  end
end
