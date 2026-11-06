# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchHelper do
  describe '#render_search_bar' do
    it 'uses the current keyword search instead of a previous search' do
      html = helper.render_search_bar(current_search_form: ResultsSearchForm.new(query: 'Miller'),
                                      last_search_form: ResultsSearchForm.new(query: 'octopus'))
      page = Capybara.string(html)

      expect(URI.parse(page.find('form')[:action]).path).to eq('/search')
      expect(page).to have_field('Search for', with: 'Miller')
    end

    it 'preserves the workflow view when searching from its bar' do
      html = helper.render_search_bar(current_search_form: WorkflowGridSearchForm.new(query: 'Miller'),
                                      last_search_form: nil)
      page = Capybara.string(html)

      expect(URI.parse(page.find('form')[:action]).path).to eq('/workflow_grid')
      expect(page).to have_field('Search for', with: 'Miller')
    end

    it 'uses the last keyword search when there is no current search' do
      html = helper.render_search_bar(current_search_form: nil,
                                      last_search_form: ResultsSearchForm.new(query: 'octopus'))
      page = Capybara.string(html)

      expect(URI.parse(page.find('form')[:action]).path).to eq('/search')
      expect(page).to have_field('Search for', with: 'octopus')
    end

    it 'starts a fresh keyword search when the current query is advanced' do
      html = helper.render_search_bar(current_search_form: AdvancedSearchForm.new(query: 'Miller OR octopus'),
                                      last_search_form: ResultsSearchForm.new(query: 'Miller'))
      page = Capybara.string(html)

      expect(URI.parse(page.find('form')[:action]).path).to eq('/search')
      expect(page.find_field('Search for').value).to be_blank
    end

    it 'starts a fresh keyword search when the last query was advanced' do
      html = helper.render_search_bar(current_search_form: nil,
                                      last_search_form: AdvancedSearchForm.new(query: 'Miller OR octopus'))
      page = Capybara.string(html)

      expect(URI.parse(page.find('form')[:action]).path).to eq('/search')
      expect(page.find_field('Search for').value).to be_blank
    end
  end
end
