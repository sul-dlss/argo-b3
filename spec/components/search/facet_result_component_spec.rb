# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FacetResultComponent, type: :component do
  let(:component) { described_class.new(value: 'Test Value', form_field: 'projects', value_counter: 1) }

  it 'renders the result' do
    render_inline(component)

    expect(page).to have_css('li#projects-result-test-value a[href="/search?projects%5B%5D=Test+Value"]',
                             text: 'Test Value')
  end
end
