# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::ItemResultComponent, type: :component do
  let(:component) { described_class.new(result:) }

  let(:result) { instance_double(SearchResults::Item, title: 'Test Title', druid: 'druid:ab123cd4567', bare_druid: 'ab123cd4567') }

  it 'renders the result' do
    render_inline(component)

    expect(page).to have_css('li#item-result-ab123cd4567', text: 'Test Title')
    expect(page).to have_link('druid:ab123cd4567', href: 'https://argo.stanford.edu/view/ab123cd4567')
  end
end
