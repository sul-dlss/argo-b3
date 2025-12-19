# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetValueComponent, type: :component do
  let(:component) do
    described_class.new(count: 10, search_form:, form_field: :object_types,
                        value: 'collection', label:, data:)
  end
  let(:search_form) { SearchForm.new(object_types: ['collection'], page: 2) }
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
    let(:search_form) { SearchForm.new(object_types: ['item'], page: 2) }

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

      expect(page).to have_content('Custom Label')
    end
  end

  context 'when link arguments are provided' do
    let(:data) { { turbo: false } }

    it 'includes the link arguments in the link' do
      render_inline(component)

      expect(page).to have_link('Remove collection', href: '/search', title: 'Remove collection')
      expect(page).to have_css('.visually-hidden', text: '[Remove collection]')
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
                                href: '/search?access_rights_exclude%5B%5D=dark&object_types%5B%5D=collection',
                                title: 'Exclude dark')
    end
  end

  context 'when exclude form field is provided and selected' do
    let(:component) do
      described_class.new(count: 10, search_form:, form_field: :access_rights,
                          exclude_form_field: :access_rights_exclude,
                          value: 'dark')
    end

    let(:search_form) { SearchForm.new(access_rights_exclude: ['dark'], object_types: ['collection'], page: 2) }

    it 'renders the exclude link' do
      render_inline(component)

      expect(page).to have_css('.selected', text: 'dark exclude')
      expect(page).to have_link('Remove dark exclude', href: '/search?object_types%5B%5D=collection')
    end
  end
end
