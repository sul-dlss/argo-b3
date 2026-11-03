# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Searchers::Item, :solr do
  let(:user_scope) { Permissions::UserScope.new(groups: create(:user, :admin).groups) }

  before do
    create(:solr_item, druid: 'druid:bc123df4567', title: 'Miller Library octopus')
    create(:solr_item, druid: 'druid:df234gh5678', title: 'Miller Library')
    create(:solr_item, druid: 'druid:gh345jk6789', title: 'Harold A. Miller')
    create(:solr_item, druid: 'druid:jk456mn7890', title: 'octopus')
    create(:solr_item, druid: 'druid:mn567pq8901', title: 'Miller Library Hopkins Marine Station Photographs')
    create(:solr_item, druid: 'druid:pq678rs9012', title: 'Miller octopus')
  end

  {
    '"Miller Library" AND NOT ("Hopkins Marine Station Photographs" OR "Hopkins Marine Station photographs")' =>
      %w[druid:bc123df4567 druid:df234gh5678],
    '"Harold A. Miller" OR octopus' =>
      %w[druid:bc123df4567 druid:gh345jk6789 druid:jk456mn7890 druid:pq678rs9012],
    'Miller AND NOT "Miller Library" AND octopus' => %w[druid:pq678rs9012],
    'Miller AND NOT ("Miller Library" AND octopus)' =>
      %w[druid:df234gh5678 druid:gh345jk6789 druid:mn567pq8901 druid:pq678rs9012],
    '"Miller Library"' => %w[druid:bc123df4567 druid:df234gh5678 druid:mn567pq8901],
    'Miller octopus' => %w[druid:bc123df4567 druid:pq678rs9012]
  }.each do |query, expected_druids|
    it "matches the Boolean expression #{query}" do
      results = described_class.call(search_form: AdvancedSearchForm.new(query:), user_scope:)

      expect(results.map(&:druid)).to match_array(expected_druids)
    end
  end
end
