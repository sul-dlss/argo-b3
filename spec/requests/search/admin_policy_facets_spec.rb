# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin policy facets', :solr do
  before do
    create(:solr_item)
    sign_in(create(:user))
  end

  it_behaves_like 'a simple facet controller',
                  index_path: :search_admin_policy_facets_path,
                  search_path: :search_search_admin_policy_facets_path,
                  facet_frame_fragment: 'turbo-frame id="admin-policy-titles-facet-page1"',
                  facet_value: 'University Archives',
                  search_query: 'Archives'
end
