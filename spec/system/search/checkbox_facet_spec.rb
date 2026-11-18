# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Checkbox facets', :solr do
  before do
    languages = Search::Facets::LANGUAGES.with(limit: 2)
    %w[ALL SIDEBAR SECONDARY].each do |name|
      configs = Search::Facets.const_get(name)
      stub_const("Search::Facets::#{name}",
                 configs.map { |config| config == Search::Facets::LANGUAGES ? languages : config })
    end
    create_list(:solr_item, 3, languages: ['English'])
    create_list(:solr_item, 2, languages: ['French'])
    create(:solr_item, languages: ['German'])
    sign_in(create(:user, :reader))
  end

  it 'returns focus to the facet when the checked value is not shown after the update' do
    visit search_path(query: 'test')
    find_facet_section('Language').click
    find_facet_more_link('Language').click

    within(find_facet_section('Language')) { check('German') }

    expect(page).to have_current_filter('Language', 'German')
    # German was on the second page of values, which is not shown once the facet reloads.
    expect(page).to have_button('Language', focused: true)
  end
end
