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
        expect(request).to include(fq: ['id:("druid:bc123df4567")'], fl: %w[id display_title_ss])
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
      expect(TrackedDeposit.where(in_error: true)).to be_empty
      expect(user.notifications).to be_empty
      expect(Search::SolrService).to have_received(:post).once do |request:|
        expect(request).to include(fl: %w[id wf_error_ssim])
      end
    end
  end

  context 'when the tracked version is in error' do
    let(:statuses) do
      { 'druid:bc123df4567' => version_status(version: 2, open: true),
        'druid:cd234fg5678' => version_status(version: 2, open: true),
        'druid:df345gh6789' => version_status(version: 2, open: true) }
    end
    let(:solr_docs) do
      [{ 'id' => 'druid:bc123df4567', 'wf_error_ssim' => ['assemblyWF:jp2-create:failed'] },
       { 'id' => 'druid:cd234fg5678' }, { 'id' => 'druid:df345gh6789' }]
    end

    before do
      create(:tracked_deposit, druid: 'druid:bc123df4567', version: 2, user:)
      create(:tracked_deposit, druid: 'druid:cd234fg5678', version: 2, user:)
      create(:tracked_deposit, druid: 'druid:df345gh6789', version: 2, user:, in_error: true)
      create(:content, :mutable, druid: 'druid:cd234fg5678', staging_state: 'staging_failed')
    end

    it 'records which have a Process in error or failed staging, and keeps tracking them' do
      perform

      expect(TrackedDeposit.where(in_error: true).pluck(:druid)).to contain_exactly('druid:bc123df4567',
                                                                                    'druid:cd234fg5678')
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

  describe 'Multi-Item Deposits' do
    let(:multi_item_deposit_action) do
      create(:multi_item_deposit_action, user:, description: 'Maps', step: 'submitted',
                                         initiating_deposit_started_at: 1.hour.ago,
                                         initiating_deposit_completed_at: 1.hour.ago)
    end
    let(:druids) { %w[druid:bc123df4567 druid:cd234fg5678] }
    let(:solr_docs) { druids.map { |druid| { 'id' => druid } } }
    let(:statuses) { druids.index_with { version_status(version: 2, open: true) } }

    before do
      druids.each do |druid|
        item_deposit_action = create(:item_deposit_action, multi_item_deposit_action:, druid:)
        create(:tracked_deposit, druid:, version: 2, user:, item_deposit_action:)
      end
      allow(objects_client).to receive(:statuses) { statuses.slice(*druids) }
    end

    def complete(druid)
      statuses[druid] = version_status(version: 2)
    end

    def fail_process(druid)
      solr_docs.find { |doc| doc['id'] == druid }['wf_error_ssim'] = ['accessionWF:shelve:failed']
    end

    def retry_process(druid)
      solr_docs.find { |doc| doc['id'] == druid }.delete('wf_error_ssim')
      TrackedDeposit.retried!(druid:)
    end

    # Polls without sending emails that are due later.
    def poll
      perform_enqueued_jobs(except: Noticed::DeliveryMethods::Email) { described_class.perform_now }
      perform_enqueued_jobs(only: Noticed::DeliveryMethods::Email, at: Time.current)
    end

    def send_due_emails
      perform_enqueued_jobs(only: Noticed::DeliveryMethods::Email)
    end

    def emails
      ActionMailer::Base.deliveries
    end

    def notification_titles
      user.notifications.includes(:event).sort_by { |notification| notification.event.created_at }.map(&:title)
    end

    context 'when a MID Item Deposit is still in flight' do
      before do
        complete('druid:bc123df4567')
        poll
      end

      it 'does not notify, even for a Complete MID Item Deposit, and ends its tracking' do
        expect(user.notifications).to be_empty
        expect(TrackedDeposit.pluck(:druid)).to eq(['druid:cd234fg5678'])
        expect(multi_item_deposit_action.reload.settled_at).to be_nil
      end
    end

    context 'when an early MID Item Deposit is In Error' do
      before do
        fail_process('druid:bc123df4567')
        poll
      end

      it 'does not notify or start a clock' do
        expect(user.notifications).to be_empty
        expect(Noticed::DeliveryMethods::Email).not_to have_been_enqueued
        expect(multi_item_deposit_action.reload.settled_at).to be_nil
      end
    end

    context 'when every MID Item Deposit is Complete' do
      before do
        druids.each { |druid| complete(druid) }
        poll
      end

      it 'notifies the owner with a toast, an inbox entry, and an email immediately' do
        notification = user.notifications.sole
        expect(notification).to be_a(MultiItemDepositSettledNotifier::Notification)
        expect(notification.record).to eq(multi_item_deposit_action)
        expect(notification.params).to include(error_count: 0, item_deposit_count: 2)
        expect(notification.title).to eq('Multi-item deposit complete')
        expect(notification.detail).to be_nil
        expect(toast_html.sole).to have_css('.toast.toast-disappear', text: 'Multi-item deposit complete')
        expect(toast_html.sole).to have_link("All items of #{multi_item_deposit_action.name} were deposited.",
                                             href: "/multi_item_deposit_actions/#{multi_item_deposit_action.id}")

        email = emails.sole
        expect(email.to).to eq([user.email_address])
        expect(email.subject).to eq("Maps SDR multi-item deposit #{multi_item_deposit_action.id} complete")
        expect(Capybara.string(email.body.to_s)).to have_css(
          'p', text: "Your SDR multi-item deposit #{multi_item_deposit_action.id} (Maps) is complete: every item " \
                     'has been deposited.'
        )
        expect(multi_item_deposit_action.reload.settled_email_sent_at).to be_within(1.second).of(Time.current)
      end

      it 'no longer notifies once the settled email has gone out' do
        multi_item_deposit_action.update!(settled_at: nil)
        poll

        expect(user.notifications.count).to eq(1)
      end
    end

    context 'when the last MID Item Deposit is Complete and another is In Error' do
      before do
        fail_process('druid:bc123df4567')
        poll
        complete('druid:cd234fg5678')
        poll
      end

      it 'notifies the owner with a red toast and an inbox entry immediately' do
        notification = user.notifications.sole
        expect(notification.params).to include(error_count: 1, item_deposit_count: 2)
        expect(notification.title).to eq('Multi-item deposit completed with errors')
        expect(notification.detail).to eq('1 of 2 items has errors.')
        expect(toast_html.sole).to have_css('.toast .bg-stanford-digital-red',
                                            text: 'Multi-item deposit completed with errors')
        expect(toast_html.sole).to have_no_css('.toast-disappear')
        expect(toast_html.sole).to have_link("#{multi_item_deposit_action.name} completed with errors in 1 item.")
      end

      it 'emails 10 minutes after settling' do
        expect(emails).to be_empty
        expect(Noticed::DeliveryMethods::Email).to have_been_enqueued
          .at(be_within(5.seconds).of(10.minutes.from_now))

        send_due_emails

        email = emails.sole
        expect(email.subject).to eq("Maps SDR multi-item deposit #{multi_item_deposit_action.id} completed with errors")
        expect(Capybara.string(email.body.to_s)).to have_css('p', text: 'has completed with errors: 1 item of 2 ' \
                                                                        'could not be deposited.')
        expect(multi_item_deposit_action.reload.settled_email_sent_at).to be_present
      end

      it 'no longer notifies of settling once the email has gone out' do
        travel 10.minutes
        send_due_emails
        retry_process('druid:bc123df4567')
        fail_process('druid:bc123df4567')
        poll

        expect(user.notifications.count).to eq(1)
      end
    end

    context 'when a MID Item Deposit could not be started' do
      before do
        multi_item_deposit_action.item_deposit_actions.find_by(druid: 'druid:bc123df4567')
                                 .update!(deposit_errors: ['An unexpected error occurred while depositing.'])
        TrackedDeposit.find_by(druid: 'druid:bc123df4567').destroy!
        complete('druid:cd234fg5678')
        poll
      end

      it 'counts it as In Error' do
        expect(user.notifications.sole.params).to include(error_count: 1)
      end
    end

    context 'when a MID Item Deposit failed staging' do
      before do
        create(:content, :mutable, druid: 'druid:bc123df4567', staging_state: 'staging_failed')
        complete('druid:cd234fg5678')
        poll
      end

      it 'counts it as In Error' do
        expect(user.notifications.sole.params).to include(error_count: 1)
      end

      it 'unsettles when staging is retried, cancelling the email' do
        Content.find_by(druid: 'druid:bc123df4567').start_staging!(user:, accession: true)

        expect(multi_item_deposit_action.reload.settled_at).to be_nil
        expect { send_due_emails }.not_to(change(emails, :count))
      end
    end

    context 'when a MID Item Deposit is no longer in flight' do
      before do
        statuses['druid:bc123df4567'] = version_status(version: 1)
        complete('druid:cd234fg5678')
        poll
      end

      it 'records it as In Error rather than Complete' do
        expect(multi_item_deposit_action.item_deposit_actions.find_by(druid: 'druid:bc123df4567').deposit_errors)
          .to eq(['The deposit stopped before it was complete: the draft was discarded or the object purged.'])
        expect(user.notifications.sole.params).to include(error_count: 1)
      end
    end

    context 'when Solr still shows a Process in error just after it was retried' do
      before do
        fail_process('druid:bc123df4567')
        complete('druid:cd234fg5678')
        poll
        TrackedDeposit.retried!(druid: 'druid:bc123df4567')
        poll
      end

      it 'stays unsettled until the grace period has passed' do
        expect(multi_item_deposit_action.reload.settled_at).to be_nil
        expect(user.notifications.count).to eq(1)

        travel TrackedDeposit::RETRY_GRACE_PERIOD + 1.second
        poll

        expect(user.notifications.count).to eq(2)
      end
    end

    context 'when notifying of settling fails' do
      before do
        druids.each { |druid| complete(druid) }
        allow(Honeybadger).to receive(:notify)
      end

      it 'undoes settling, so the next run notifies' do
        allow(MultiItemDepositSettledNotifier).to receive(:with).and_raise(ActiveRecord::ConnectionNotEstablished)
        poll

        expect(multi_item_deposit_action.reload.settled_at).to be_nil
        expect(Honeybadger).to have_received(:notify)

        allow(MultiItemDepositSettledNotifier).to receive(:with).and_call_original
        poll

        expect(user.notifications.count).to eq(1)
      end

      it 'keeps settling if the Notification was made, so the next run does not notify again' do
        allow(MultiItemDepositSettledNotifier).to receive(:with).and_wrap_original do |original, **params|
          original.call(**params).tap do |event|
            allow(event).to receive(:deliver).and_wrap_original do |deliver, *args, **options|
              deliver.call(*args, **options)
              raise ActiveRecord::ConnectionNotEstablished
            end
          end
        end
        poll

        expect(multi_item_deposit_action.reload.settled_at).to be_present
        expect(user.notifications.count).to eq(1)
      end
    end

    # The worked example in the spec: settled with errors, then a retry within the 10 minutes.
    describe 'retrying within the 10 minutes' do
      before do
        fail_process('druid:bc123df4567')
        complete('druid:cd234fg5678')
        poll
        travel 5.minutes
        retry_process('druid:bc123df4567')
      end

      it 'cancels the email when the retry has not finished by then, and notifies when it settles again' do
        travel 5.minutes
        poll
        send_due_emails

        expect(emails).to be_empty
        expect(notification_titles).to eq(['Multi-item deposit completed with errors'])

        travel 30.minutes
        complete('druid:bc123df4567')
        poll

        expect(notification_titles).to eq(['Multi-item deposit completed with errors', 'Multi-item deposit complete'])
        expect(emails.sole.subject).to end_with('complete')
      end

      it 'cancels the email when the retry has finished with errors, and starts a new 10-minute clock' do
        travel 2.minutes
        fail_process('druid:bc123df4567')
        poll
        travel 3.minutes
        # The first email is due, but the second is not.
        perform_enqueued_jobs(only: Noticed::DeliveryMethods::Email, at: Time.current)

        expect(emails).to be_empty
        expect(notification_titles).to eq(['Multi-item deposit completed with errors'] * 2)

        travel 5.minutes
        send_due_emails

        expect(emails.sole.subject).to end_with('completed with errors')
      end

      it 'cancels the email when the retry has finished Complete, emailing immediately' do
        travel 2.minutes
        complete('druid:bc123df4567')
        poll

        expect(emails.sole.subject).to end_with('complete')

        travel 10.minutes
        send_due_emails

        expect(emails.count).to eq(1)
      end
    end
  end
end
