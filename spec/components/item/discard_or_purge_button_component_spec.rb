# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Item::DiscardOrPurgeButtonComponent, type: :component do
  let(:druid) { 'druid:bc123df4567' }
  let(:version_service) { instance_double(Sdr::VersionService, druid:, open?: true, discardable?: true) }
  let(:discard_or_purge_presenter) { DiscardOrPurgePresenter.new(cocina_version:, version_service:) }
  let(:cocina_version) { 2 }

  context 'when purgeable' do
    let(:cocina_version) { 1 }

    before do
      allow(Sdr::PurgeService).to receive(:purgeable?).and_return(true)
    end

    it 'renders the purge button' do
      render_inline(described_class.new(discard_or_purge_presenter:))

      expect(page).to have_css('a[href="/objects/druid:bc123df4567/purge"][data-turbo-method="delete"]' \
                               '[data-turbo-confirm^="Purge this object?"]', text: 'Purge')
    end
  end

  context 'when discardable' do
    it 'renders the discard draft button' do
      render_inline(described_class.new(discard_or_purge_presenter:))

      expect(page).to have_css('a[href="/objects/druid:bc123df4567/discard_draft"][data-turbo-method="delete"]' \
                               '[data-turbo-confirm^="Discard this draft?"]', text: 'Discard draft')
    end
  end

  context 'with data' do
    it 'renders the data on the link' do
      render_inline(described_class.new(discard_or_purge_presenter:, data: { disable_actions_target: 'disableable' }))

      expect(page).to have_css('a[data-disable-actions-target="disableable"][data-turbo-method="delete"]' \
                               '[data-turbo-confirm^="Discard this draft?"]', text: 'Discard draft')
    end
  end

  context 'when not available' do
    let(:version_service) { instance_double(Sdr::VersionService, druid:, open?: true, discardable?: false) }

    it 'renders nothing' do
      render_inline(described_class.new(discard_or_purge_presenter:))

      expect(page).to have_no_link
    end
  end
end
