# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dates facets', :solr do
  before do
    create(:solr_item)
    sign_in(create(:user))
  end

  it_behaves_like 'a simple facet controller',
                  index_path: :search_date_facets_path,
                  search_path: :search_search_date_facets_path,
                  facet_frame_fragment: 'turbo-frame id="dates-facet-page1"',
                  facet_value: '2001',
                  search_query: '2001'
end
