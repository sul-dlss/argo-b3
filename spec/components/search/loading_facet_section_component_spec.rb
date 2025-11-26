# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::LoadingFacetSectionComponent, type: :component do
  let(:component) do
    described_class.new(label: 'Projects')
  end

  it 'renders placeholders' do
    render_inline(component)

    expect(page).to have_css('section.accordion[aria-label="Loading Projects"]')
    expect(page).to have_css('section .accordion-item .accordion-header button.accordion-button[disabled] .spinner-border') # rubocop:disable Layout/LineLength
  end
end
