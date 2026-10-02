# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FieldValueResultComponent, type: :component do
  let(:component) do
    described_class.new(value: 'Test Value', form_field: 'projects', value_counter: 4, visible_limit: 5)
  end

  it 'renders the result' do
    render_inline(component)

    expect(page).to have_css('li#projects-result-test-value a[href="/search?projects%5B%5D=Test+Value"]',
                             text: 'Test Value')
    expect(page).to have_no_css('li.d-none', visible: :all)
  end

  context 'when the result is past the visible limit' do
    let(:component) do
      described_class.new(value: 'Test Value', form_field: 'projects', value_counter: 5, visible_limit: 5)
    end

    it 'hides the result' do
      render_inline(component)

      expect(page).to have_css('li#projects-result-test-value.d-none[data-show-more-target="hidden"]', visible: :all)
    end
  end
end
