# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search::FieldValueResultsComponent, type: :component do
  let(:component) { described_class.new(label: 'Project results', values:, form_field: 'projects') }

  context 'when there are no results' do
    let(:values) { [] }

    it 'does not render' do
      render_inline(component)

      expect(page).to have_no_css('section')
    end
  end

  context 'when there are fewer results than the initial limit' do
    let(:values) { ['Project A', 'Project B'] }

    it 'renders all of the results without a More link' do
      render_inline(component)

      expect(page).to have_css('section[aria-label="Project results"] h3', text: 'Project results (2 found)')
      expect(page).to have_css('li', count: 2)
      expect(page).to have_no_css('li.d-none')
      expect(page).to have_no_button('More »')
    end
  end

  context 'when there are more results than the initial limit' do
    let(:values) { (1..7).map { |number| "Project #{number}" } }

    it 'hides the results past the initial limit and renders a More link' do
      render_inline(component)

      expect(page).to have_css('section[aria-label="Project results"] h3', text: 'Project results (7 found)')
      expect(page).to have_css('li', count: 7)
      expect(page).to have_css('li.d-none[data-show-more-target="hidden"]', count: 2, visible: :all)
      expect(page).to have_css('li#projects-result-project-6.d-none', visible: :all)
      expect(page).to have_button('More »')
    end
  end
end
