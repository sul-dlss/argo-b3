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

  it 'lists a checked value that is not among the top values' do
    visit search_path(query: 'test')
    find_facet_section('Language').click
    find_facet_more_link('Language').click

    within(find_facet_section('Language')) { check('German') }

    expect(page).to have_current_filter('Language', 'German')
    # German was on the second page of values, so it follows the top values once the facet reloads.
    within(find_facet_section('Language')) do
      expect(page).to have_checked_field('German', focused: true)
      expect(all('.form-check-label').map(&:text)).to eq(%w[English French German])
    end

    # So is an excluded value.
    within(find_facet_section('Language')) { click_link('Exclude German') }

    expect(page).to have_current_filter('Language exclude', 'German')
    expect(page).to have_excluded_facet_value('German', facet: 'Language')
  end
end
