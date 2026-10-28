# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Item::DiscardOrPurgeButtonComponent, type: :component do
  let(:druid) { 'druid:bc123df4567' }

  context 'when purgeable' do
    it 'renders the purge button' do
      render_inline(described_class.new(druid:, action: :purge))

      expect(page).to have_css('a[href="/objects/druid:bc123df4567/purge"][data-turbo-method="delete"]' \
                               '[data-turbo-confirm^="Purge this object?"]', text: 'Purge')
    end
  end

  context 'when discardable' do
    it 'renders the discard draft button' do
      render_inline(described_class.new(druid:, action: :discard_draft))

      expect(page).to have_css('a[href="/objects/druid:bc123df4567/discard_draft"][data-turbo-method="delete"]' \
                               '[data-turbo-confirm^="Discard this draft?"]', text: 'Discard draft')
    end
  end

  context 'with data' do
    it 'renders the data on the link' do
      render_inline(described_class.new(druid:, action: :discard_draft,
                                        data: { disable_actions_target: 'disableable' }))

      expect(page).to have_css('a[data-disable-actions-target="disableable"][data-turbo-method="delete"]' \
                               '[data-turbo-confirm^="Discard this draft?"]', text: 'Discard draft')
    end
  end

  context 'without an action' do
    it 'renders nothing' do
      render_inline(described_class.new(druid:, action: nil))

      expect(page).to have_no_link
    end
  end
end
