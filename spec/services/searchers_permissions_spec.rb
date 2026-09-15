# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers, :solr do
  let(:user) { create(:user, :reader) }
  let(:restricted_apo_druid) { 'druid:bc123df4567' }
  let!(:visible_document) do
    create(:solr_item, projects: ['Visible project'], workflows: ['accessionWF:publish:completed'])
  end
  let!(:hidden_document) do
    create(:solr_item, apo_druid: restricted_apo_druid, projects: ['Hidden project'], content_type: 'image',
                       workflows: ['accessionWF:publish:completed'])
  end
  let(:search_form) { SearchForm.new(query: 'Test') }

  before do
    Current.effective_groups = user.groups
    create(:permission, :read_restricted, workgroup: 'sdr:other-group', target_druid: restricted_apo_druid)
  end

  it 'filters results, counts, and facets without excluding the authorization filter from facet domains' do
    results = Searchers::Item.call(search_form:)

    expect(results.map(&:druid)).to eq([visible_document.fetch(Search::Fields::ID)])
    expect(results.total_results).to eq(1)
    expect(results.solr_response.fetch('facets').fetch(Search::Fields::CONTENT_TYPES).fetch('buckets'))
      .to eq([{ 'val' => 'book', 'count' => 1 }])
  end

  it 'filters report previews and streamed downloads for explicitly supplied druids' do
    druids = [visible_document, hidden_document].pluck(Search::Fields::ID)
    fields = [Search::Fields::ID]
    preview = Searchers::ReportByDruid.call(druids:, fields:, rows: 10)
    stream = StringIO.new
    Searchers::ReportByDruid.call(druids:, fields:, rows: 10, stream:)

    expect(preview.map(&:fields).flatten).to eq([visible_document.fetch(Search::Fields::ID)])
    expect(stream.string).to include(visible_document.fetch(Search::Fields::ID))
    expect(stream.string).not_to include(hidden_document.fetch(Search::Fields::ID))
  end

  it 'filters reports and bulk-action selections generated from a search' do
    report = Searchers::Report.call(search_form:, fields: [Search::Fields::ID], rows: 10)
    druids = Searchers::DruidList.call(search_form:)

    expect(report.map(&:fields).flatten).to eq([visible_document.fetch(Search::Fields::ID)])
    expect(druids).to eq([visible_document.fetch(Search::Fields::ID)])
  end

  it 'filters dashboard lists and tag suggestions' do
    documents = Searchers::ItemByDruid.call(druids: [visible_document, hidden_document].pluck(Search::Fields::ID))
    tags = Searchers::Tag.call(search_form: SearchForm.new(query: 'project'),
                               field: Search::Fields::PROJECTS_EXPLODED)

    expect(documents.map(&:druid)).to eq([visible_document.fetch(Search::Fields::ID)])
    expect(tags.to_a).to eq(['Visible project'])
  end

  it 'filters the workflow grid and its reset selection to readable objects' do
    counts = Searchers::Workflow.call(search_form:)
    druids = Searchers::DruidList.call(search_form:)

    expect(counts.count_for(workflow_name: 'accessionWF', process_name: 'publish', status: 'completed')).to eq(1)
    expect(druids).to eq([visible_document.fetch(Search::Fields::ID)])
  end

  it 'uses the visible result set for previous and next navigation' do
    navigation = Searchers::ItemNavigation.call(search_form:, position: 1)

    expect(navigation.total_results).to eq(1)
    expect(navigation.previous_druid).to be_nil
    expect(navigation.next_druid).to be_nil
  end

  it 'retains authorization when a facet excludes its own selected filter' do
    results = Searchers::Item.call(search_form: SearchForm.new(query: 'Test', content_types: ['image']))

    expect(results.total_results).to eq(0)
    expect(results.solr_response.fetch('facets').fetch(Search::Fields::CONTENT_TYPES).fetch('buckets'))
      .to eq([{ 'val' => 'book', 'count' => 1 }])
  end
end
