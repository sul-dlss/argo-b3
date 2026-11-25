# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PollTrackedDepositsJob do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:objects_client) { instance_double(Dor::Services::Client::Objects, statuses:) }
  let(:statuses) { {} }
  let(:solr_docs) { [{ 'id' => 'druid:bc123df4567', 'display_title_ss' => 'The Gettysburg Address' }] }
  let(:toast_html) { [] }

  before do
    allow(Dor::Services::Client).to receive(:objects).and_return(objects_client)
    allow(Search::SolrService).to receive(:post) do
      { 'response' => { 'numFound' => solr_docs.size, 'start' => 0, 'docs' => solr_docs } }
    end
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

  context 'when there are more Tracked Deposits than fit in a batch' do
    let(:solr_docs) do
      [{ 'id' => 'druid:bc123df4567', 'display_title_ss' => 'The Gettysburg Address' },
       { 'id' => 'druid:cd234fg5678', 'display_title_ss' => 'A Second Title' }]
    end

    before do
      stub_const("#{described_class}::BATCH_SIZE", 1)
      allow(objects_client).to receive(:statuses) do |object_ids:|
        object_ids.index_with { version_status(version: 2) }
      end
      create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, user:)
      create(:tracked_deposit, druid: 'druid:cd234fg5678', version: 2, user:)
    end

    it 'retrieves version statuses and titles for each batch' do
      perform

      expect(objects_client).to have_received(:statuses).with(object_ids: ['druid:bc123df4567']).ordered
      expect(objects_client).to have_received(:statuses).with(object_ids: ['druid:cd234fg5678']).ordered
      expect(Search::SolrService).to have_received(:post).twice
      expect(user.notifications.count).to eq(2)
      expect(TrackedDeposit.count).to eq(0)
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
      expect(Search::SolrService).to have_received(:post) do |request:|
        expect(request).to include(fq: ['id:("druid:bc123df4567")'], fl: %w[id display_title_ss wf_error_ssim])
      end
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

    let(:solr_docs) { [] }

    before { create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, user:) }

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
      expect(Search::SolrService).to have_received(:post).once
    end
  end

  context 'when a Process of the tracked version goes into error' do
    let(:statuses) { { 'druid:bc123df4567' => version_status(version: 2, accessioning: true) } }
    let(:solr_docs) do
      [{ 'id' => 'druid:bc123df4567', 'display_title_ss' => 'The Gettysburg Address',
         'wf_error_ssim' => ['accessionWF:shelve:Error: shelving failed'] }]
    end
    let!(:tracked_deposit) { create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, user:) }

    it 'notifies the depositing user that the Deposit failed, and keeps tracking' do
      perform

      notification = user.notifications.sole
      expect(notification.params).to include(druid: 'druid:bc123df4567', version: 2, cause: 'process',
                                             title: 'The Gettysburg Address',
                                             error_summary: 'accessionWF:shelve:Error: shelving failed')
      expect(toast_html.sole).to have_link('Version 2 of The Gettysburg Address (bc123df4567) failed to deposit.',
                                           href: '/objects/druid:bc123df4567')
      expect(tracked_deposit.reload.process_errored_at).to be_present
    end

    it 'does not notify again while the Process stays in error' do
      perform
      perform

      expect(user.notifications.count).to eq(1)
    end

    context 'when the Process is retried and fails again' do
      it 'notifies again' do
        perform
        solr_docs.first.delete('wf_error_ssim')
        perform
        solr_docs.first['wf_error_ssim'] = ['accessionWF:shelve:Error: shelving failed again']
        perform

        expect(user.notifications.count).to eq(2)
        expect(Noticed::Event.order(:created_at).last.params)
          .to include(error_summary: 'accessionWF:shelve:Error: shelving failed again')
      end
    end
  end

  context 'when the object of an in-flight Deposit is not in Solr' do
    let(:statuses) { { 'druid:bc123df4567' => version_status(version: 2, accessioning: true) } }
    let(:solr_docs) { [] }
    let!(:tracked_deposit) do
      create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, user:, process_errored_at: 1.hour.ago)
    end

    it 'leaves its errors as they were' do
      perform

      expect(tracked_deposit.reload.process_errored_at).to be_present
      expect(user.notifications).to be_empty
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

  context 'when notifying fails' do
    let(:statuses) do
      { 'druid:bc123df4567' => version_status(version: 2), 'druid:cd234fg5678' => version_status(version: 1) }
    end
    let(:solr_docs) do
      [{ 'id' => 'druid:bc123df4567', 'display_title_ss' => 'The Gettysburg Address' },
       { 'id' => 'druid:cd234fg5678', 'display_title_ss' => 'Maps of Palo Alto' }]
    end

    before do
      create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, user:)
      create(:tracked_deposit, druid: 'druid:cd234fg5678', version: 1, user:)
      allow(Honeybadger).to receive(:notify)
      allow(DepositCompleteNotifier).to receive(:with).and_call_original
      allow(DepositCompleteNotifier).to receive(:with).with(hash_including(druid: 'druid:bc123df4567'))
                                                      .and_raise(ActiveRecord::ConnectionNotEstablished)
    end

    it 'keeps tracking the deposit, so the next run notifies, and notifies of the others' do
      perform

      expect(TrackedDeposit.pluck(:druid)).to eq(['druid:bc123df4567'])
      expect(user.notifications.sole.params).to include(druid: 'druid:cd234fg5678')
      expect(Honeybadger).to have_received(:notify)
    end
  end

  context 'when there are more Tracked Deposits than fit in one statuses request' do
    # Varying the first two and the last two characters.
    let(:prefixes) { %w[bc cd df fg gh hj jk km mn np pq qr rs st tv vw wx xy yz zb bd cf dg fh gj hk] }
    let(:druids) { prefixes.map { |prefix| "druid:#{prefix}123df45#{prefix}" } }

    before { druids.each { |druid| create(:tracked_deposit, druid:, version: 2, user:) } }

    it 'retrieves the statuses in batches of 25 druids' do
      perform

      expect(objects_client).to have_received(:statuses).with(object_ids: druids.first(25))
      expect(objects_client).to have_received(:statuses).with(object_ids: druids.last(1))
    end
  end
end
