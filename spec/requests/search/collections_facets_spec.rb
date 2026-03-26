# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collections facets', :solr do
  before do
    create(:solr_item)
    sign_in(create(:user))
  end

  it_behaves_like 'a simple facet controller',
                  index_path: :search_collection_facets_path,
                  search_path: :search_search_collection_facets_path,
                  facet_frame_fragment: 'turbo-frame id="collection-titles-facet-page1"',
                  facet_value: 'David Rumsey Map Collection',
                  search_query: 'Rumsey'
end
