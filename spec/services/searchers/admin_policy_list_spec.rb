# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::AdminPolicyList do
  let(:apo_options) { described_class.call(user_scope:) }
  let(:user) { create(:user, :admin) }
  let(:user_scope) { Permissions::UserScope.new(groups: user.groups) }
  let(:solr_response) do
    {
      'response' => {
        'numFound' => 2,
        'docs' => [
          { 'id' => 'druid:bc123df4567', 'display_title_ss' => 'APO One' },
          { 'id' => 'druid:xz987wv6543', 'display_title_ss' => 'APO Two' }
        ]
      }
    }
  end

  before do
    allow(Search::SolrService).to receive(:post).and_return(solr_response)
  end

  it 'returns [title, druid] pairs from Solr, sorted by title' do
    expect(apo_options).to eq([['APO One', 'druid:bc123df4567'], ['APO Two', 'druid:xz987wv6543']])

    expect(Search::SolrService).to have_received(:post) do |args|
      solr_query = args[:request].with_indifferent_access
      expect(solr_query['fq']).to eq(["#{Search::Fields::OBJECT_TYPES}:APO"])
      expect(solr_query['fl']).to eq([Search::Fields::ID, Search::Fields::TITLE])
      expect(solr_query['sort']).to eq("#{Search::Fields::SORT_TITLE} asc, id asc")
    end
  end

  context 'with a non-admin user' do
    let(:user) { create(:user) }

    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: 'druid:bc123df4567')
    end

    it 'restricts the APOs to those the user can access' do
      apo_options

      expect(Search::SolrService).to have_received(:post) do |args|
        expect(args[:request][:fq]).to eq(
          ["#{Search::Fields::OBJECT_TYPES}:APO",
           "(#{Search::Fields::ID}:(\"druid\\:bc123df4567\") OR " \
           "#{Search::Fields::COLLECTION_DRUIDS}:(\"druid\\:bc123df4567\") OR " \
           "#{Search::Fields::APO_DRUID}:(\"druid\\:bc123df4567\"))"]
        )
      end
    end
  end
end
