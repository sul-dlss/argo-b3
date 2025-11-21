# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::DynamicFacetBuilder do
  it 'builds the dynamic facet json' do
    expect(described_class.call(
             form_field: :released_to_earthworks,
             dynamic_facet: Search::Facets::RELEASED_TO_EARTHWORKS.dynamic_facet
           )).to eq({
                      'released_to_earthworks-ever' => {
                        q: 'released_to_earthworks_dtpsidv:[* TO *]',
                        type: 'query'
                      },
                      'released_to_earthworks-last_month' => {
                        q: 'released_to_earthworks_dtpsidv:[NOW-1MONTH/DAY TO NOW]',
                        type: 'query'
                      },
                      'released_to_earthworks-last_week' => {
                        q: 'released_to_earthworks_dtpsidv:[NOW-7DAY/DAY TO NOW]',
                        type: 'query'
                      },
                      'released_to_earthworks-last_year' => {
                        q: 'released_to_earthworks_dtpsidv:[NOW-1YEAR/DAY TO NOW]',
                        type: 'query'
                      },
                      'released_to_earthworks-never' => {
                        q: '-released_to_earthworks_dtpsidv:[* TO *]',
                        type: 'query'
                      }
                    })
  end
end
