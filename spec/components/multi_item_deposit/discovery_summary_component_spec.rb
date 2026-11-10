# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::DiscoverySummaryComponent, type: :component do
  let(:component) { described_class.new(multi_item_deposit_action:) }
  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, discovery_started_at: Time.zone.parse('2026-06-27T06:08:56Z'),
                                       discovery_completed_at: Time.zone.parse('2026-06-27T06:10:00Z'))
  end

  context 'when Item Deposits have discovery errors' do
    before do
      # Created out of manifest order, so that the content types must be ordered by manifest line.
      create(:item_deposit_action, multi_item_deposit_action:, manifest_line_number: 3, content_type: 'object',
                                   discovery_errors: ['Object not found'])
      create(:item_deposit_action, multi_item_deposit_action:, manifest_line_number: 2, content_type: 'book',
                                   discovery_errors: ['Not an Item', 'Folder not found: folder1'])
      create(:item_deposit_action, multi_item_deposit_action:, manifest_line_number: 4, content_type: 'book',
                                   discovery_warnings: ['Version cannot be opened'])
      create(:item_deposit_action, multi_item_deposit_action:, manifest_line_number: 5)
      # Another Multi-Item Deposit's Item Deposit.
      create(:item_deposit_action, content_type: 'map', discovery_errors: ['Object not found'])
    end

    it 'renders the heading and when checking the manifest started' do
      render_inline(component)

      expect(page).to have_css('h3', text: 'Summary')
      expect(page).to have_text('Started 2026-06-26 23:08:56 PT')
    end

    it 'renders the number of items' do
      render_inline(component)

      expect(page).to have_css('.summary-box', text: '# of items') do |box|
        box.has_css?('.summary-box-value', text: '4')
      end
    end

    it 'renders the number of errors as danger' do
      render_inline(component)

      expect(page).to have_css('.summary-box.text-danger', text: '# of errors') do |box|
        box.has_css?('.summary-box-value', text: '3')
      end
    end

    it 'renders the content types in manifest order' do
      render_inline(component)

      expect(page).to have_css('.summary-box', text: 'Content types') do |box|
        box.has_css?('.summary-box-value', text: 'Book, file')
      end
    end

    it 'does not render a report download or structural metadata' do
      render_inline(component)

      expect(page).to have_no_link('Download report')
      expect(page).to have_no_text('Structural metadata')
    end
  end

  context 'when no Item Deposits have discovery errors' do
    before do
      create(:item_deposit_action, multi_item_deposit_action:, content_type: 'image')
    end

    it 'renders the number of errors as success' do
      render_inline(component)

      expect(page).to have_css('.summary-box.text-success', text: '# of errors') do |box|
        box.has_css?('.summary-box-value', text: '0')
      end
    end
  end

  context 'when no Item Deposits have a content type' do
    before do
      create(:item_deposit_action, multi_item_deposit_action:, discovery_errors: ['Object not found'])
    end

    it 'does not render the content types' do
      render_inline(component)

      expect(page).to have_no_text('Content types')
    end
  end
end
