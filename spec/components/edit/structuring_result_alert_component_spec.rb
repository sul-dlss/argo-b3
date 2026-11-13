# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Edit::StructuringResultAlertComponent, type: :component do
  let(:populator_selection) do
    Contents::PopulatorSelector::Result.new(Contents::Populators::Book, Contents::Populators::Book, [])
  end

  it 'renders the model used in a dismissible info alert' do
    render_inline(described_class.new(structuring_result: 'structured', populator_selection:))

    expect(page).to have_css('.alert-info.alert-dismissible',
                             text: 'Files were structured with the Book (resource per page) model.')
    expect(page).to have_css('button.btn-close[aria-label="Close"]')
  end

  context 'when the model for the content type was not used' do
    let(:populator_selection) do
      Contents::PopulatorSelector::Result.new(Contents::Populators::Book, Contents::Populators::FileSetPerFile,
                                              %i[hierarchical_filepaths no_images])
    end

    it 'renders the model used and the reasons in a warning alert' do
      render_inline(described_class.new(structuring_result: 'structured', populator_selection:))

      alert = page.find('.alert-warning')
      expect(alert).to have_text('Files were structured with the Default (resource per file) model.')
      expect(alert).to have_text('The Book (resource per page) model was not used because:')
      expect(alert.all('li').map(&:text)).to eq(['the files are organized into folders', 'there are no image files'])
    end
  end

  context 'when structuring failed' do
    it 'renders the failure in a danger alert' do
      render_inline(described_class.new(structuring_result: 'structuring_failed', populator_selection:))

      expect(page).to have_css('.alert-danger', text: 'Structuring files failed. Try again, or contact SDR support')
      expect(page).to have_no_text('Book')
    end
  end

  context 'without a result' do
    it 'renders nothing' do
      render_inline(described_class.new(structuring_result: nil, populator_selection:))

      expect(page).to have_no_css('.alert')
    end
  end
end
