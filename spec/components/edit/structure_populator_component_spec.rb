# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::StructurePopulatorComponent, type: :component do
  let(:component) { described_class.new(content_record:, populator_selection:) }
  let(:content_record) { create(:content, :mutable, druid: 'druid:bc123df4567') }
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

    it 'renders the button to structure the files' do
      render_inline(component)

      form = page.find('fieldset[data-disable-actions-target="disableable"] form[action="/contents/druid:bc123df4567"]')
      expect(form).to have_css('input[name="_method"][value="patch"]', visible: :hidden)
      expect(form).to have_css('input[name="commit"][value="restructure"]', visible: :hidden)
      expect(form).to have_button('Structure files', class: 'btn-outline-primary')
    end
  end

  context 'when the files have been structured' do
    let(:populator_for_content_type) { Contents::Populators::Book }
    let(:actual_populator) { Contents::Populators::Book }
    let(:reasons) { [] }

    before { create(:content_file_set, content: content_record) }

    it 'renders the button to structure the files again' do
      render_inline(component)

      expect(page).to have_button('Clear and structure files again')
    end
  end

  context 'when the fallback populator is being used' do
    let(:populator_for_content_type) { Contents::Populators::Book }
    let(:actual_populator) { Contents::Populators::FileSetPerFile }
    let(:reasons) { %i[hierarchical_filepaths no_images] }

    it 'renders the fallback strategy and the reasons' do
      render_inline(component)

      expect(page).to have_css('p', text: 'Strategy for structuring: Default (resource per file)')
      expect(page).to have_css('p', text: 'Reasons for not using Book (resource per page)')
      expect(page).to have_css('li', text: 'the files are organized into folders')
      expect(page).to have_css('li', text: 'there are no image files')
    end
  end
end
