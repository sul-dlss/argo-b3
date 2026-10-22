# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::ObjectStatusPresentersBuilder do
  subject(:object_status_presenters) { described_class.call(item_deposit_actions:, initiating:) }

  let(:initiating) { false }

  let(:item_deposit_actions) { [second_item_deposit_action, first_item_deposit_action, missing_item_deposit_action] }
  let(:first_item_deposit_action) { build(:item_deposit_action, druid: 'druid:bc123df4567', content:) }
  let(:second_item_deposit_action) { build(:item_deposit_action, druid: 'druid:cd234fg5678') }
  let(:missing_item_deposit_action) { build(:item_deposit_action, druid: 'druid:df345gh6789') }
  let(:druids) { ['druid:cd234fg5678', 'druid:bc123df4567', 'druid:df345gh6789'] }
  let(:content) { build(:content, staging_state: 'staging') }

  let(:first_document) { SearchResults::Item.new(solr_doc: build(:solr_item, druid: 'druid:bc123df4567')) }
  let(:second_document) do
    SearchResults::Item.new(solr_doc: build(:solr_item, druid: 'druid:cd234fg5678',
                                                        workflow_errors: ['accessionWF:shelve:Oops']))
  end
  let(:closed_status) do
    Dor::Services::Client::ObjectVersion::VersionStatus.new(open: false, openable: true, assembling: false,
                                                            accessioning: false, closeable: false)
  end
  let(:open_status) do
    Dor::Services::Client::ObjectVersion::VersionStatus.new(open: true, openable: false, assembling: false,
                                                            accessioning: false, closeable: true)
  end

  before do
    allow(Searchers::ItemByDruid).to receive(:call).and_return([first_document, second_document])
    allow(Sdr::VersionService).to receive(:statuses)
      .and_return({ 'druid:bc123df4567' => open_status, 'druid:cd234fg5678' => closed_status,
                    'druid:df345gh6789' => closed_status })
  end

  it 'returns presenters in the order of the Item Deposits, omitting those without a Solr doc' do
    expect(object_status_presenters.map(&:druid)).to eq(['druid:cd234fg5678', 'druid:bc123df4567'])

    expect(object_status_presenters[0].status).to eq(:error)
    expect(object_status_presenters[0].version_editable?).to be true
    expect(object_status_presenters[1].status).to eq(:staging)
    expect(object_status_presenters[1].version_editable?).to be true

    expect(Searchers::ItemByDruid).to have_received(:call)
      .with(druids:, user_scope: nil, fields: [Search::Fields::ID, Search::Fields::WORKFLOW_ERRORS]).once
    expect(Sdr::VersionService).to have_received(:statuses).with(druids:).once
  end

  context 'when the Content is not staging' do
    let(:content) { nil }

    it 'uses the bulk retrieved version status' do
      expect(object_status_presenters[1].status).to eq(:draft)
    end
  end

  context 'when initiating' do
    let(:initiating) { true }
    let(:second_item_deposit_action) do
      build(:item_deposit_action, druid: 'druid:cd234fg5678', deposit_errors: ['Deposit failed'])
    end
    let(:third_item_deposit_action) { build(:item_deposit_action, druid: 'druid:df345gh6789') }
    let(:item_deposit_actions) { [second_item_deposit_action, first_item_deposit_action, third_item_deposit_action] }
    let(:third_document) { SearchResults::Item.new(solr_doc: build(:solr_item, druid: 'druid:df345gh6789')) }

    before do
      allow(Searchers::ItemByDruid).to receive(:call).and_return([first_document, second_document, third_document])
    end

    it 'returns initiating for Item Deposits that have not started staging and have no deposit errors' do
      expect(object_status_presenters.map(&:status)).to eq(%i[error staging initiating])
    end
  end

  context 'when there are no Item Deposits' do
    let(:item_deposit_actions) { [] }

    it 'returns no presenters without retrieving' do
      expect(object_status_presenters).to eq([])

      expect(Searchers::ItemByDruid).not_to have_received(:call)
      expect(Sdr::VersionService).not_to have_received(:statuses)
    end
  end
end
