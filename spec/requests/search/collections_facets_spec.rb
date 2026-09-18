# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collections facets', :solr do
  let(:collection_druid) { 'druid:bc123df4567' }
  let(:collection_title) { 'David Rumsey Map Collection' }

  before do
    create(:solr_item, collection_druids: [collection_druid])
    create(:solr_collection, druid: collection_druid, title: collection_title)
    sign_in(create(:user, :reader))
  end

  it_behaves_like 'a simple facet controller',
                  index_path: :search_collection_facets_path,
                  search_path: :search_search_collection_facets_path,
                  facet_frame_fragment: 'turbo-frame id="collection-druids-facet-page1"',
                  facet_value: 'David Rumsey Map Collection',
                  facet_search_value: 'druid:bc123df4567',
                  search_query: 'Rumsey'
end
