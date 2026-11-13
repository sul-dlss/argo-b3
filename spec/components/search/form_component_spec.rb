# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FormComponent, type: :component do
  let(:component) { described_class.new(current_search_form: search_form) }

  context 'when no facets are selected' do
    let(:search_form) { ResultsSearchForm.new(query: 'test') }

    it 'renders the search form' do
      render_inline(component)

      expect(URI.parse(page.find('form')[:action]).path).to eq('/search')
      expect(page).to have_field('Search for', type: :search, with: 'test')
      expect(page).to have_select('Select object type', with_options: ['All object types', 'Item', 'Collection'])
      expect(page).to have_button('Search')
    end
  end

  context 'when facets are selected' do
    let(:search_form) { ResultsSearchForm.new(query: 'test', projects: ['Google Books']) }

    it 'renders the search form' do
      render_inline(component)

      expect(URI.parse(page.find('form')[:action]).path).to eq('/search')
      expect(page).to have_field('projects[]', type: :hidden, with: 'Google Books')
      expect(page).to have_field('Search for', type: :search, with: 'test')
    end
  end

  it 'uses the current keyword search instead of a previous search' do
    render_inline(described_class.new(current_search_form: ResultsSearchForm.new(query: 'Miller'),
                                      last_search_form: ResultsSearchForm.new(query: 'octopus')))

    expect(URI.parse(page.find('form')[:action]).path).to eq('/search')
    expect(page).to have_field('Search for', with: 'Miller')
  end

  it 'preserves the workflow view when searching from its bar' do
    render_inline(described_class.new(current_search_form: WorkflowGridSearchForm.new(query: 'Miller')))

    expect(URI.parse(page.find('form')[:action]).path).to eq('/workflow_grid')
    expect(page).to have_field('Search for', with: 'Miller')
  end

  it 'uses the last keyword search when there is no current search' do
    render_inline(described_class.new(last_search_form: ResultsSearchForm.new(query: 'octopus')))

    expect(URI.parse(page.find('form')[:action]).path).to eq('/search')
    expect(page).to have_field('Search for', with: 'octopus')
  end

  it 'starts a fresh keyword search when the current query is advanced' do
    render_inline(described_class.new(current_search_form: AdvancedSearchForm.new(query: 'Miller OR octopus'),
                                      last_search_form: ResultsSearchForm.new(query: 'Miller')))

    expect(URI.parse(page.find('form')[:action]).path).to eq('/search')
    expect(page.find_field('Search for').value).to be_blank
  end

  it 'starts a fresh keyword search when the last query was advanced' do
    render_inline(described_class.new(last_search_form: AdvancedSearchForm.new(query: 'Miller OR octopus')))

    expect(URI.parse(page.find('form')[:action]).path).to eq('/search')
    expect(page.find_field('Search for').value).to be_blank
  end
end
