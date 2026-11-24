# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Facet And/Or toggle', :solr do
  let!(:english_spanish_item_doc) { create(:solr_item, languages: %w[English Spanish]) }

  before do
    create(:solr_item, languages: ['English'])
    create(:solr_item, languages: %w[Spanish German])
    create(:solr_item, languages: ['French'])
    sign_in(create(:user, :reader))
  end

  it 'combines the checked languages with And or Or' do
    visit search_path(query: 'test')
    find_facet_section('Language').click

    within(find_facet_section('Language')) do
      expect(page).to have_checked_field('Or', visible: :all)
      check('English')
    end
    within(find_facet_section('Language')) { check('Spanish') }

    expect(page).to have_result_count(3)
    expect(page).to have_current_filter('Language', 'English OR Spanish')

    within(find_facet_section('Language')) { choose('And', allow_label_click: true) }

    expect(page).to have_result_count(1)
    expect(page).to have_item_result(english_spanish_item_doc)
    expect(page).to have_current_filter('Language', 'English AND Spanish')
    within(find_facet_section('Language')) do
      expect(page).to have_checked_field('And', focused: true, visible: :all)
      # Counts are within the selection, so languages that don't occur with both drop out.
      expect(all('.form-check-label').map(&:text)).to eq(%w[English Spanish])
    end

    within(find_facet_section('Language')) { choose('Or', allow_label_click: true) }

    expect(page).to have_result_count(3)
    expect(page).to have_current_filter('Language', 'English OR Spanish')
    within(find_facet_section('Language')) { expect(page).to have_checked_field('Or', focused: true, visible: :all) }
  end

  it 'keeps the facet open and the toggle focused when no language is checked' do
    visit search_path(query: 'test')
    find_facet_section('Language').click

    within(find_facet_section('Language')) { choose('And', allow_label_click: true) }
    expect(page).to have_current_path(/languages_operator=and/)
    within(find_facet_section('Language')) { expect(page).to have_checked_field('And', focused: true, visible: :all) }

    within(find_facet_section('Language')) { choose('Or', allow_label_click: true) }
    expect(page).to have_no_current_path(/languages_operator/)
    within(find_facet_section('Language')) { expect(page).to have_checked_field('Or', focused: true, visible: :all) }
  end
end
