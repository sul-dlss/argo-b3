# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetValueComponent, type: :component do
  let(:component) do
    described_class.new(count: 10, search_form:, form_field: :object_types,
                        value: 'collection', label:, data:)
  end
  let(:search_form) { ResultsSearchForm.new(object_types: ['collection'], page: 2) }
  let(:label) { nil }
  let(:data) { {} }

  context 'when selected' do
    it 'renders the selected facet value' do
      render_inline(component)

      expect(page).to have_css('.selected', text: 'collection')
      expect(page).to have_link('Remove collection', href: '/search')
    end
  end

  context 'when not selected' do
    let(:search_form) { ResultsSearchForm.new(object_types: ['item'], page: 2) }

    it 'renders the unselected facet value' do
      render_inline(component)

      expect(page).to have_link('collection',
                                href: '/search?object_types%5B%5D=item&object_types%5B%5D=collection')
      expect(page).to have_css('.facet-count', text: '10')
      expect(page).to have_no_link('Remove collection')
    end
  end

  context 'when a label is provided' do
    let(:label) { 'Custom Label' }

    it 'uses the provided label' do
      render_inline(component)

      expect(page).to have_text('Custom Label')
    end
  end

  context 'when link arguments are provided' do
    let(:data) { { turbo: false } }

    it 'includes the link arguments in the link' do
      render_inline(component)

      expect(page).to have_link('Remove collection', href: '/search', title: 'Remove collection')
      expect(page).to have_css('.visually-hidden', text: '[Remove collection]')
      expect(page).to have_css('a.remove i.bi-x-lg[aria-hidden="true"]')
      expect(page).to have_css('a[data-turbo="false"]')
    end
  end

  context 'when exclude form field is provided' do
    let(:component) do
      described_class.new(count: 10, search_form:, form_field: :access_rights,
                          exclude_form_field: :access_rights_exclude,
                          value: 'dark')
    end

    it 'renders the exclude link' do
      render_inline(component)

      expect(page).to have_link('dark')
      expect(page).to have_link('Exclude dark',
                                href: '/search?access_rights_exclude%5B%5D=dark&object_types%5B%5D=collection')
      expect(page).to have_css('a.btn-link .visually-hidden', text: 'Exclude dark')
      expect(page).to have_css('a.btn-link span[aria-hidden="true"]', text: 'exclude')
    end
  end

  context 'when exclude form field is provided and selected' do
    let(:component) do
      described_class.new(count: 10, search_form:, form_field: :access_rights,
                          exclude_form_field: :access_rights_exclude,
                          value: 'dark')
    end

    let(:search_form) { ResultsSearchForm.new(access_rights_exclude: ['dark'], object_types: ['collection'], page: 2) }

    it 'renders the excluded value' do
      render_inline(component)

      expect(page).to have_css('.facet-label del', text: 'dark')
      expect(page).to have_css('.facet-count', text: '10')
      expect(page).to have_css('strong', text: 'excluded')
      expect(page).to have_no_link('Exclude dark')
      expect(page).to have_link('Remove exclude dark', href: '/search?object_types%5B%5D=collection',
                                                       title: 'Remove exclude dark')
    end
  end

  context 'when exclude form field is provided and the value is excluded' do
    let(:component) do
      described_class.new(count: 10, search_form:, form_field: :access_rights,
                          exclude_form_field: :access_rights_exclude,
                          value: 'world')
    end

    let(:search_form) { ResultsSearchForm.new(access_rights: ['dark'], access_rights_exclude: ['world']) }

    it 'switches the value between selected and excluded' do
      render_inline(component)

      expect(page).to have_no_link('world', exact: true)
      expect(component.select_path).to eq('/search?access_rights%5B%5D=dark&access_rights%5B%5D=world')
      expect(component.exclude_path)
        .to eq('/search?access_rights%5B%5D=dark&access_rights_exclude%5B%5D=world')
    end
  end
end
