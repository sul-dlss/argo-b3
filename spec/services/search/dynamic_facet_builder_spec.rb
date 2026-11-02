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
                      'released_to_earthworks-last_30_days' => {
                        q: 'released_to_earthworks_dtpsidv:[NOW/DAY-30DAYS TO *]',
                        type: 'query'
                      },
                      'released_to_earthworks-last_7_days' => {
                        q: 'released_to_earthworks_dtpsidv:[NOW/DAY-7DAYS TO *]',
                        type: 'query'
                      },
                      'released_to_earthworks-today' => {
                        q: 'released_to_earthworks_dtpsidv:[NOW/DAY TO *]',
                        type: 'query'
                      },
                      'released_to_earthworks-year_to_date' => {
                        q: 'released_to_earthworks_dtpsidv:[NOW/YEAR TO *]',
                        type: 'query'
                      },
                      'released_to_earthworks-never' => {
                        q: '-released_to_earthworks_dtpsidv:[* TO *]',
                        type: 'query'
                      }
                    })
  end
end
