# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item search', :solr do
  let!(:item_doc) { create(:solr_item) }
  let!(:collection_doc) { create(:solr_collection) }

  before do
    stub_const('Searchers::Item::PER_PAGE', 5)
    create_list(:solr_item, 10)
    create(:solr_item, :google_book)
    create_list(:solr_collection, 4)
    sign_in(create(:user))
  end

  context 'when a single page of results' do
    it 'returns search results' do
      visit root_path

      expect(page).to have_css('.alert', text: 'Welcome to Argo-B3.')

      find_search_field.fill_in(with: item_doc[Search::Fields::TITLE])
      click_button('Search')

      expect(find_project_results_section).to be_nil
      within(find_item_results_section) do
        expect(page).to have_result_count(1)
        expect(page).to have_item_result(item_doc)
        expect(page).to have_no_css('ul.pagination', wait: 0)
      end
    end

    context 'when multiple pages of results' do
      it 'paginates results' do
        visit root_path

        find_search_field.fill_in(with: 'Item')
        click_button('Search')

        within(find_item_results_section) do
          expect(page).to have_result_count(11)
          expect(page).to have_current_results_page(1)
          expect(page).to have_total_results_pages(3)
          expect(page).to have_next_page
          expect(page).to have_next_page(brief: true)
          expect(page).not_to have_previous_page(wait: 0)
          expect(page).not_to have_previous_page(brief: true, wait: 0)
          find_next_page.click
        end

        within(find_item_results_section) do
          expect(page).to have_current_results_page(2)
          expect(page).to have_next_page(brief: true)
          expect(page).to have_previous_page(brief: true)
          find_next_page(brief: true).click
        end

        within(find_item_results_section) do
          expect(page).to have_current_results_page(3)
          expect(page).not_to have_next_page(wait: 0)
          expect(page).not_to have_next_page(brief: true, wait: 0)
          expect(page).to have_previous_page
          expect(page).to have_previous_page(brief: true)
          find_previous_page.click
        end

        within(find_item_results_section) do
          expect(page).to have_current_results_page(2)
        end
      end

      it 'sorts by druid' do
        visit root_path

        find_search_field.fill_in(with: 'Item')
        click_button('Search')

        within(find_item_results_section) do
          click_link_or_button('Sort by Relevance')
          find('.dropdown-item', text: 'Druid').click
        end
      end

    end

    context 'when google books are included' do
      it 'shows google books results' do
        visit root_path

        find_search_field.fill_in(with: 'Item')
        click_button('Search')

        within(find_item_results_section) do
          expect(page).to have_result_count(11)
        end

        check('Include Google Books')

        expect(page).to have_current_filter('Include Google Books')

        within(find_item_results_section) do
          expect(page).to have_result_count(12)
        end

        uncheck('Include Google Books')

        expect(page).not_to have_current_filter('Include Google Books')

        within(find_item_results_section) do
          expect(page).to have_result_count(11)
        end
      end
    end

    context 'when query is blank' do
      it 'does not return any results' do
        visit root_path

        find_search_field.fill_in(with: '')
        click_button('Search')

        expect(find_item_results_section).to be_nil
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
end
