# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::CurrentFilterComponent, type: :component do
  let(:component) { described_class.new(form_field:, values:, search_form:, facet_labels:) }
  let(:facet_labels) { {} }

  context 'when there are current filters' do
    let(:form_field) { :projects }
    let(:values) { ['Project 1'] }
    let(:search_form) do
      ResultsSearchForm.new(
        object_types: %w[item collection],
        projects: ['Project 1', 'Project 2']
      )
    end

    it 'renders the current filter' do
      render_inline(component)

      expect(page).to have_css('li', text: /Projects\s+❯\s+Project 1/)
      expect(page).to have_link('', href: '/search?object_types%5B%5D=item&object_types%5B%5D=collection' \
                                          '&projects%5B%5D=Project+2',
                                    title: 'Remove Projects > Project 1')
    end
  end

  context 'when a filter has multiple (ORed) values' do
    let(:form_field) { :object_types }
    let(:values) { %w[item collection] }
    let(:search_form) do
      ResultsSearchForm.new(
        object_types: %w[item collection],
        projects: ['Project 1']
      )
    end

    it 'renders the values in a single current filter' do
      render_inline(component)

      expect(page).to have_css('li', text: /Object types\s+❯\s+item OR collection/)
      expect(page).to have_link('',
                                href: '/search?projects%5B%5D=Project+1',
                                title: 'Remove Object types > item OR collection')
    end
  end

  context 'when a filter for a dynamic facet' do
    let(:form_field) { :released_to_earthworks }
    let(:values) { ['last_year'] }
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
    let(:values) { ['druid:bc123df4567'] }
    let(:search_form) { ResultsSearchForm.new(admin_policy_druids: values) }
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
