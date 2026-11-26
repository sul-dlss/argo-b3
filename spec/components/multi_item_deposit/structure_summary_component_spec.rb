# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::StructureSummaryComponent, type: :component do
  let(:component) { described_class.new(multi_item_deposit_action:, summary:) }
  let(:multi_item_deposit_action) do
    build_stubbed(:multi_item_deposit_action, structuring_started_at: Time.zone.parse('2026-06-24T06:08:56Z'),
                                              structuring_completed_at: Time.zone.parse('2026-06-24T06:10:00Z'))
  end
  let(:summary) do
    MultiItemDeposit::StructureResults::Summary.new(item_count: 1200, items_with_errors_count: 10, file_count: 3,
                                                    file_size: 61_500_000, mime_types: %w[image/jp2 image/tiff])
  end

  it 'renders the heading and when checking the files started' do
    render_inline(component)

    expect(page).to have_css('h3', text: 'Summary')
    expect(page).to have_text('Started 2026-06-23 23:08:56 PT')
  end

  it 'renders a link to download the report' do
    render_inline(component)

    expect(page).to have_link('Download report',
                              href: "/multi_item_deposit_actions/#{multi_item_deposit_action.id}/structure_report")
    expect(page).to have_css('a[download] i[aria-hidden="true"]')
  end

  it 'renders the boxes in a compact row, with less padding' do
    render_inline(component)

    expect(page).to have_css('.box-row-compact > .show-box > .card > .card-body.p-2', count: 3)
    expect(page).to have_css('.box-row-compact h4.card-title.fs-6.fw-bold', count: 3)
  end

  it 'renders the number of items' do
    render_inline(component)

    expect(page).to have_css('.object-type-multi-item-deposit .card', text: '# of items') do |box|
      box.has_css?('h4.card-title', text: '# of items') && box.has_css?('.card-text p', exact_text: '1,200')
    end
  end

  it 'renders the number of Item Deposits with errors as danger' do
    render_inline(component)

    expect(page).to have_css('.card.text-danger', text: '# with errors') do |box|
      box.has_css?('h4.card-title', text: '# with errors') && box.has_css?('.card-text p', exact_text: '10')
    end
  end

  it 'renders the number and total size of the files' do
    render_inline(component)

    expect(page).to have_css('.card', text: 'Total size') do |box|
      box.has_css?('h4.card-title', text: 'Total size') &&
        box.has_css?('.card-text p', exact_text: '3 files / 58.7 MB')
    end
  end

  it 'renders the MIME types' do
    render_inline(component)

    expect(page).to have_css('p', exact_text: 'MIME types: image/jp2, image/tiff')
  end

  context 'when no Item Deposits have structure errors' do
    let(:summary) do
      MultiItemDeposit::StructureResults::Summary.new(item_count: 1, items_with_errors_count: 0, file_count: 1,
                                                      file_size: 1000, mime_types: ['image/tiff'])
    end

    it 'renders the number of Item Deposits with errors as success' do
      render_inline(component)

      expect(page).to have_css('.card.text-success', text: '# with errors') do |box|
        box.has_css?('.card-text p', exact_text: '0')
      end
    end

    it 'renders the file in the singular' do
      render_inline(component)

      expect(page).to have_css('.card', text: 'Total size') do |box|
        box.has_css?('.card-text p', exact_text: '1 file / 1000 Bytes')
      end
    end
  end

  context 'when there are thousands of files' do
    let(:summary) do
      MultiItemDeposit::StructureResults::Summary.new(item_count: 2, items_with_errors_count: 0, file_count: 1000,
                                                      file_size: 0, mime_types: ['image/tiff'])
    end

    it 'renders the number of files with delimiters' do
      render_inline(component)

      expect(page).to have_css('.card', text: 'Total size') do |box|
        box.has_css?('.card-text p', exact_text: '1,000 files / 0 Bytes')
      end
    end
  end

  context 'when no files were discovered' do
    let(:summary) do
      MultiItemDeposit::StructureResults::Summary.new(item_count: 1, items_with_errors_count: 1, file_count: 0,
                                                      file_size: 0, mime_types: [])
    end

    it 'does not render the MIME types' do
      render_inline(component)

      expect(page).to have_no_text('MIME types')
    end
  end
end
