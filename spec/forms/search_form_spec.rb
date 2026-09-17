# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchForm do
  describe 'abstractness' do
    it 'does not provide permitted params' do
      expect { described_class.permitted_params }.to raise_error(NotImplementedError)
    end

    it 'does not provide a route scope' do
      expect { described_class.route_scope }.to raise_error(NotImplementedError)
    end
  end

  describe '#with' do
    let(:form) { ResultsSearchForm.new(query: 'twain', tags: ['Registered By : jdoe'], page: 4) }

    it 'returns a form of the same class' do
      expect(form.with(object_types: ['item'])).to be_an_instance_of(ResultsSearchForm)
    end

    it 'drops attributes that the class does not declare' do
      # Facet links reset page when the filters change, but not every view has a page.
      expect(WorkflowGridSearchForm.new(query: 'twain').with(object_types: ['item'], page: nil).attributes)
        .to eq({ 'query' => 'twain', 'object_types' => ['item'] })
    end
  end

  describe '#without' do
    it 'returns a form of the same class' do
      form = WorkflowGridSearchForm.new(query: 'twain', tags: ['a'])

      expect(form.without(:tags)).to be_an_instance_of(WorkflowGridSearchForm)
    end
  end

  describe '#as' do
    let(:query_attributes) do
      {
        query: 'twain',
        object_types: %w[item collection],
        tags: ['Registered By : jdoe'],
        registered_date_from: Date.new(2024, 1, 1)
      }
    end

    it 'converts to the other view, dropping attributes it does not declare' do
      results_form = ResultsSearchForm.new(**query_attributes, page: 4, sort: 'title')

      grid_form = results_form.as(WorkflowGridSearchForm)

      expect(grid_form).to be_an_instance_of(WorkflowGridSearchForm)
      expect(grid_form.attributes).to eq(ResultsSearchForm.new(**query_attributes).attributes.except('page', 'sort'))
    end

    it 'round-trips the query attributes and resets the presentation attributes' do
      round_tripped = ResultsSearchForm.new(**query_attributes, page: 4, sort: 'title')
                                       .as(WorkflowGridSearchForm)
                                       .as(ResultsSearchForm)

      expect(round_tripped.attributes).to eq(ResultsSearchForm.new(**query_attributes).attributes)
      expect(round_tripped.page).to eq(1)
      expect(round_tripped.sort).to be_nil
    end

    it 'returns itself when already the requested class' do
      form = ResultsSearchForm.new(query: 'twain')

      expect(form.as(ResultsSearchForm)).to be(form)
    end
  end

  describe 'view capabilities' do
    it 'describes the search results view' do
      expect(ResultsSearchForm.new).to have_attributes(route_scope: 'search', pinnable?: true, sortable?: true,
                                                       item_results?: true)
    end

    it 'describes the workflow grid view' do
      expect(WorkflowGridSearchForm.new).to have_attributes(route_scope: 'workflow_grid', pinnable?: false,
                                                            sortable?: false, item_results?: false)
    end
  end
end
