# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'APO facets', :solr do
  let(:apo_druid) { 'druid:bc123df4567' }
  let(:apo_title) { 'University Archives' }

  before do
    create(:solr_item, apo_druid:)
    create(:solr_collection, druid: apo_druid, title: apo_title, object_type: 'APO')
    sign_in(create(:user, :reader))
  end

  it_behaves_like 'a simple facet controller',
                  index_path: :search_admin_policy_facets_path,
                  search_path: :search_search_admin_policy_facets_path,
                  facet_frame_fragment: 'turbo-frame id="admin-policy-druids-facet-page1"',
                  facet_value: 'University Archives',
                  facet_search_value: 'druid:bc123df4567',
                  search_query: 'Archives'
end
