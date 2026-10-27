# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Missing value facet', :solr do
  let!(:no_language_item_doc) { create(:solr_item, languages: []) }

  before do
    create(:solr_item, languages: ['English'])
    sign_in(create(:user, :reader))
  end

  it 'filters on objects without a value' do
    visit search_path(query: 'test')

    expect(page).to have_result_count(2)

    find_facet_section('Language').click
    expect(page).to have_facet_value('No value', count: 1, facet: 'Language')
    expect(page).to have_facet_value('English', count: 1, facet: 'Language')

    within(find_facet_section('Language')) do
      click_link('No value')
    end

    expect(page).to have_result_count(1)
    expect(page).to have_item_result(no_language_item_doc)
    expect(page).to have_current_filter('Language', 'No value')
  end
end
