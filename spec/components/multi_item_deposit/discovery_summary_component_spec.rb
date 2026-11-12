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

    it 'renders the heading and when checking the manifest completed' do
      render_inline(component)

      expect(page).to have_css('h3', text: 'Summary')
      expect(page).to have_text('Completed 2026-06-26 23:10:00 PT')
      expect(page).to have_no_text('Started')
    end

    it 'renders a link to download the report' do
      render_inline(component)

      expect(page).to have_link('Download report',
                                href: "/multi_item_deposit_actions/#{multi_item_deposit_action.id}/discovery_report")
      expect(page).to have_css('a[download] i[aria-hidden="true"]')
    end

    it 'renders the number of items' do
      render_inline(component)

      expect(page).to have_css('.object-type-multi-item-deposit .card', text: '# of items') do |box|
        box.has_css?('h4.card-title', text: '# of items') && box.has_css?('.card-text p', exact_text: '4')
      end
    end

    it 'renders the number of Item Deposits with errors as danger' do
      render_inline(component)

      # Two Item Deposits have errors, one of them two errors.
      expect(page).to have_css('.card.text-danger', text: '# of errors') do |box|
        box.has_css?('h4.card-title', text: '# of errors') && box.has_css?('.card-text p', exact_text: '2')
      end
    end

    it 'renders the content types in manifest order' do
      render_inline(component)

      expect(page).to have_css('.card', text: 'Content types') do |box|
        box.has_css?('h4.card-title', text: 'Content types') && box.has_css?('.card-text p', exact_text: 'Book, file')
      end
    end

    it 'does not render structural metadata' do
      render_inline(component)

      expect(page).to have_no_text('Structural metadata')
    end
  end

  context 'when no Item Deposits have discovery errors' do
    before do
      create(:item_deposit_action, multi_item_deposit_action:, content_type: 'image')
    end

    it 'renders the number of errors as success' do
      render_inline(component)

      expect(page).to have_css('.card.text-success', text: '# of errors') do |box|
        box.has_css?('.card-text p', exact_text: '0')
      end
    end

    it 'renders a link to download the report' do
      render_inline(component)

      expect(page).to have_link('Download report')
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
