# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::StructurePopulatorDescriptionComponent, type: :component do
  let(:component) { described_class.new(populator_selection:) }
  let(:populator_selection) do
    Contents::PopulatorSelector::Result.new(populator_for_content_type:, actual_populator:, reasons:)
  end

  context 'when the populator for the content type is being used' do
    let(:populator_for_content_type) { Contents::Populators::Book }
    let(:actual_populator) { Contents::Populators::Book }
    let(:reasons) { [] }

    it 'renders the strategy without any reasons' do
      render_inline(component)

      expect(page).to have_css('p', text: 'Strategy for structuring: Book (resource per page)')
      expect(page).to have_no_text('Reasons for not using')
      expect(page).to have_no_css('li')
    end
  end

  context 'when the fallback populator is being used' do
    let(:populator_for_content_type) { Contents::Populators::Book }
    let(:actual_populator) { Contents::Populators::FileSetPerFile }
    let(:reasons) { %i[dark no_images] }

    it 'renders the fallback strategy and the reasons' do
      render_inline(component)

      expect(page).to have_css('p', text: 'Strategy for structuring: Default (resource per file)')
      expect(page).to have_css('p', text: 'Reasons for not using Book (resource per page)')
      expect(page).to have_css('li', text: 'the object is dark')
      expect(page).to have_css('li', text: 'there are no image files')
    end
  end
end
