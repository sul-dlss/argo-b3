# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetsBuilder do
  subject(:facet_json) { described_class.call(facet_configs:).with_indifferent_access }

  let(:facet_configs) do
    [
      Search::Facets::OBJECT_TYPES,
      Search::Facets::ACCESS_RIGHTS,
      Search::Facets::RELEASED_TO_EARTHWORKS
    ]
  end

  it 'returns facet json' do
    expect(facet_json).to include(
      Search::Fields::OBJECT_TYPES,
      Search::Fields::ACCESS_RIGHTS
    )
    expect(facet_json[Search::Fields::ACCESS_RIGHTS])
      .to match({
                  field: Search::Fields::ACCESS_RIGHTS,
                  limit: 50,
                  numBuckets: true,
                  sort: 'index',
                  type: 'terms'
                })
    # Only testing one dynamic facet here so that the test is not brittle.
    expect(facet_json).to include(
      "#{Search::Facets::RELEASED_TO_EARTHWORKS.form_field}-last_week",
      "#{Search::Facets::RELEASED_TO_EARTHWORKS.form_field}-last_month",
      "#{Search::Facets::RELEASED_TO_EARTHWORKS.form_field}-last_year",
      "#{Search::Facets::RELEASED_TO_EARTHWORKS.form_field}-ever",
      "#{Search::Facets::RELEASED_TO_EARTHWORKS.form_field}-never"
    )
    expect(facet_json["#{Search::Facets::RELEASED_TO_EARTHWORKS.form_field}-last_week"])
      .to match({
                  type: 'query',
                  q: "#{Search::Fields::RELEASED_TO_EARTHWORKS}:[NOW-7DAY/DAY TO *]"
                })
  end
end
