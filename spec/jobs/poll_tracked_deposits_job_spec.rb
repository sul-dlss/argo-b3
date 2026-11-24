# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PollTrackedDepositsJob do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:objects_client) { instance_double(Dor::Services::Client::Objects, statuses:) }
  let(:statuses) { {} }
  let(:solr_item) do
    SearchResults::Item.new(solr_doc: { Search::Fields::ID => 'druid:bc123df4567',
                                        Search::Fields::TITLE => 'The Gettysburg Address' })
  end
  let(:toast_html) { [] }

  before do
    allow(Dor::Services::Client).to receive(:objects).and_return(objects_client)
    allow(Searchers::ItemByDruid).to receive(:call).and_return([solr_item])
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to) do |*_args, html:, **|
      toast_html << Capybara.string(html)
    end
  end

  def version_status(version:, open: false, accessioning: false)
    Dor::Services::Client::ObjectVersion::VersionStatus.new(versionId: version, open:, accessioning:)
  end

  def perform
    perform_enqueued_jobs { described_class.perform_now }
  end

  context 'when there are no Tracked Deposits' do
    it 'does not retrieve version statuses' do
      perform

      expect(Dor::Services::Client).not_to have_received(:objects)
    end
  end

  context 'when the tracked version is Complete' do
    let(:statuses) { { 'druid:bc123df4567' => version_status(version: 2) } }

    before { create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, user:) }

    it 'notifies the depositing user with a toast and a notification, and ends tracking' do
      perform

      notification = user.notifications.sole
      expect(notification.record).to be_nil
      expect(notification.params).to include(druid: 'druid:bc123df4567', version: 2,
                                             title: 'The Gettysburg Address')
      expect(notification.title).to eq('Deposit complete')
      expect(toast_html.sole).to have_link('Version 2 of The Gettysburg Address (bc123df4567) was deposited.',
                                           href: '/objects/druid:bc123df4567')
      expect(TrackedDeposit.count).to eq(0)
      expect(objects_client).to have_received(:statuses).with(object_ids: ['druid:bc123df4567'])
      expect(Searchers::ItemByDruid).to have_received(:call)
        .with(druids: ['druid:bc123df4567'], user_scope: nil, fields: [Search::Fields::ID, Search::Fields::TITLE])
    end
  end

  context 'when a later version has been opened' do
    let(:statuses) { { 'druid:bc123df4567' => version_status(version: 3, open: true) } }

    before { create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, user:) }

    it 'notifies that the tracked version is Complete' do
      perform

      expect(user.notifications.sole.params).to include(version: 2)
      expect(TrackedDeposit.count).to eq(0)
    end
  end

  context 'when the object is not in Solr' do
    let(:statuses) { { 'druid:bc123df4567' => version_status(version: 2) } }

    before do
      allow(Searchers::ItemByDruid).to receive(:call).and_return([])
      create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, user:)
    end

    it 'uses the druid as the title' do
      perform

      expect(user.notifications.sole.params).to include(title: 'bc123df4567')
    end
  end

  context 'when the tracked version is still in flight' do
    let(:statuses) do
      { 'druid:bc123df4567' => version_status(version: 2, open: true),
        'druid:cd234fg5678' => version_status(version: 1, accessioning: true) }
    end

    before do
      create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, user:)
      create(:tracked_deposit, druid: 'druid:cd234fg5678', version: 1, user:)
    end

    it 'keeps tracking without notifying' do
      perform

      expect(TrackedDeposit.pluck(:druid)).to contain_exactly('druid:bc123df4567', 'druid:cd234fg5678')
      expect(user.notifications).to be_empty
      expect(Searchers::ItemByDruid).not_to have_received(:call)
    end
  end

  context 'when the tracked version is no longer in flight' do
    # The draft was discarded, returning to version 1, and the other object was purged.
    let(:statuses) { { 'druid:bc123df4567' => version_status(version: 1) } }

    before do
      create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, user:)
      create(:tracked_deposit, druid: 'druid:cd234fg5678', version: 1, user:)
    end

    it 'ends tracking silently' do
      perform

      expect(TrackedDeposit.count).to eq(0)
      expect(user.notifications).to be_empty
    end
  end

  context 'when there are more Tracked Deposits than fit in one statuses request' do
    let(:druids) { Array.new(26) { |index| format('druid:bc%<index>03ddf%<index>04d', index:) } }

    before { druids.each { |druid| create(:tracked_deposit, druid:, version: 2, user:) } }

    it 'retrieves the statuses in batches of 25 druids' do
      perform

      expect(objects_client).to have_received(:statuses).with(object_ids: druids.first(25))
      expect(objects_client).to have_received(:statuses).with(object_ids: druids.last(1))
    end
  end
end
