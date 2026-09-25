# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item search', :solr do
  let(:user) { create(:user, :reader) }
  let!(:item_doc) { create(:solr_item) }
  let!(:collection_doc) { create(:solr_collection) }

  before do
    stub_const('Searchers::Item::PER_PAGE', 5)
    create_list(:solr_item, 10)
    create_list(:solr_collection, 4)
    sign_in(user)
  end

  context 'when a single page of results' do
    it 'returns search results' do
      visit search_path

      find_search_field.fill_in(with: item_doc[Search::Fields::TITLE])
      click_button('Search')

      expect(page).to have_css('turbo-frame#projects-search[complete]')
      expect(page).to have_no_css('section[aria-label="Project results"]')
      within(find_item_results_section) do
        expect(page).to have_result_count(1)
        expect(page).to have_item_result(item_doc)
        expect(page).to have_no_css('ul.pagination', wait: 0)
      end
    end

    it 'pins and unpins a search result' do
      visit search_path(query: item_doc[Search::Fields::TITLE])

      within("#item-result-#{item_doc[Search::Fields::BARE_DRUID]} caption") do
        expect(page).to have_button('Pin')
        click_button('Pin')
      end

      expect(page).to have_toast('Pin added')
      within("#item-result-#{item_doc[Search::Fields::BARE_DRUID]} caption") do
        expect(page).to have_button('Unpin')
        click_button('Unpin')
      end

      expect(page).to have_toast('Pin removed')
      within("#item-result-#{item_doc[Search::Fields::BARE_DRUID]} caption") do
        expect(page).to have_button('Pin')
      end
    end

    context 'when multiple pages of results' do
      it 'paginates results' do
        visit search_path

        find_search_field.fill_in(with: 'Item')
        click_button('Search')

        within('turbo-frame#items-search') do
          expect(page).to have_result_count(11)
          expect(page).to have_current_results_page(1)
          expect(page).to have_total_results_pages(3)
          expect(page).to have_next_page
          expect(page).to have_next_page(brief: true)
          expect(page).not_to have_previous_page(wait: 0)
          expect(page).not_to have_previous_page(brief: true, wait: 0)
          find_next_page.click

          expect(page).to have_current_results_page(2)
          expect(page).to have_next_page(brief: true)
          expect(page).to have_previous_page(brief: true)
          find_next_page(brief: true).click

          expect(page).to have_current_results_page(3)
          expect(page).not_to have_next_page(wait: 0)
          expect(page).not_to have_next_page(brief: true, wait: 0)
          expect(page).to have_previous_page
          expect(page).to have_previous_page(brief: true)
          find_previous_page.click

          expect(page).to have_current_results_page(2)
        end

        expect(page).to have_current_path(%r{/search\?.*page=2})

        visit page.current_url

        within('turbo-frame#items-search') do
          expect(page).to have_current_results_page(2)
        end
      end

      it 'verifies sort options' do
        visit search_path

        find_search_field.fill_in(with: 'Item')
        click_button('Search')

        within(find_item_results_section) do
          click_link_or_button('Sort by Relevance')
          expect(page.all('.dropdown-item').map(&:text)).to eq(['Relevance',
                                                                'Last deposited date (ascending)',
                                                                'Last deposited date (descending)',
                                                                'Registered date (ascending)',
                                                                'Registered date (descending)',
                                                                'Source ID',
                                                                'Title',
                                                                'Druid'])

          click_link_or_button('Registered date (descending)')
          expect(page).to have_button('Sort by Registered date (descending)')
          expect(page).to have_result_count(11)
        end

        expect(page).to have_current_path(%r{/search\?.*sort=registered_date_desc})

        visit page.current_url

        within(find_item_results_section) do
          expect(page).to have_button('Sort by Registered date (descending)')
        end
      end
    end

    context 'when query is blank' do
      let(:user) { create(:user, :admin) }

      it 'returns all results' do
        visit search_path

        find_search_field.fill_in(with: '')
        click_button('Search')

        within(find_item_results_section) do
          expect(page).to have_result_count(16)
        end
      end
    end

    context 'when selecting an object type from the search bar' do
      it 'filters results by the selected object type' do
        visit search_path

        find_search_field.fill_in(with: 'Test')
        find_object_type_field.select('Collection')
        click_button('Search')

        expect(page).to have_current_filter('Object types', 'collection')
        within(find_item_results_section) do
          expect(page).to have_result_count(5)
          expect(page).to have_item_result(collection_doc)
        end
      end
    end

    context 'when there is a current filter' do
      it 'applies the current filter when searching' do
        visit search_path('object_types[]': 'collection')

        expect(page).to have_result_count(5)
        expect(page).to have_current_filter('Object types', 'collection')

        find_search_field.fill_in(with: collection_doc[Search::Fields::TITLE])
        click_button('Search')

        expect(page).to have_result_count(1)
        expect(page).to have_current_filter('Object types', 'collection')
      end
    end
  end

  context 'when the user does not have read permission' do
    let(:user) { create(:user) }

    it 'does not return search results' do
      visit search_path

      find_search_field.fill_in(with: item_doc[Search::Fields::TITLE])
      click_button('Search')

      expect(page).to have_css('turbo-frame#items-search[complete]')
      expect(page).to have_no_css('section[aria-label="Item, collection, and APO results"]')
      expect(page).not_to have_item_result(item_doc)
    end
  end
end
