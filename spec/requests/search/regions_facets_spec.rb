# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Regions facets', :solr do
  before do
    create(:solr_item)
    sign_in(create(:user))
  end

  it_behaves_like 'a simple facet controller',
                  index_path: :search_region_facets_path,
                  search_path: :search_search_region_facets_path,
                  facet_frame_fragment: 'turbo-frame id="regions-facet-page1"',
                  facet_value: 'Palo Alto',
                  search_query: 'Palo Alto'
end
