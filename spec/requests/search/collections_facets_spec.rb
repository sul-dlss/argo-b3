# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collections facets', :solr do
  before do
    create(:solr_item, collection_druids: ['druid:gh456jk7890'], collection_titles: ['David Rumsey Map Collection'])
    sign_in(create(:user, :reader))
  end

  it_behaves_like 'a simple facet controller',
                  index_path: :search_collection_facets_path,
                  search_path: :search_search_collection_facets_path,
                  facet_frame_fragment: 'turbo-frame id="collection-druids-facet-page1"',
                  facet_value: 'druid:gh456jk7890',
                  facet_label: 'David Rumsey Map Collection',
                  search_query: 'Rumsey'
end
