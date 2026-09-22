# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::CurrentFilterComponent, type: :component do
  let(:component) { described_class.new(form_field:, value:, search_form:, facet_labels:) }
  let(:facet_labels) { {} }

  context 'when there are current filters' do
    let(:form_field) { :object_types }
    let(:value) { 'item' }
    let(:search_form) do
      ResultsSearchForm.new(
        object_types: %w[item collection],
        projects: ['Project 1']
      )
    end

    it 'renders the current filter' do
      render_inline(component)

      expect(page).to have_css('li', text: /Object types\s+❯\s+item/)
      expect(page).to have_link('',
                                href: '/search?object_types%5B%5D=collection&projects%5B%5D=Project+1',
                                title: 'Remove Object types > item')
    end
  end

  context 'when a filter for a dynamic facet' do
    let(:form_field) { :released_to_earthworks }
    let(:value) { 'last_year' }
    let(:search_form) do
      ResultsSearchForm.new(
        released_to_earthworks: ['last_year']
      )
    end

    it 'renders the current filter' do
      render_inline(component)

      expect(page).to have_css('li', text: /Released to Earthworks\s+❯\s+Last year/)
    end
  end

  context 'when a filter for a composite facet (e.g. Admin Policies)' do
    let(:form_field) { :admin_policy_druids }
    let(:value) { 'druid:bc123df4567' }
    let(:search_form) { ResultsSearchForm.new(admin_policy_druids: [value]) }
    let(:facet_labels) { { 'druid:bc123df4567' => 'University Archives' } }

    it 'renders the resolved label instead of the raw druid' do
      render_inline(component)

      expect(page).to have_css('li', text: /APOs\s+❯\s+University Archives/)
    end

    context 'when the druid has no resolved label' do
      let(:facet_labels) { {} }

      it 'falls back to the raw druid' do
        render_inline(component)

        expect(page).to have_css('li', text: /APOs\s+❯\s+druid:bc123df4567/)
      end
    end
  end
end
