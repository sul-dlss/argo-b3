# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DepositFailedNotifier do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }
  let(:url) { "http://example.com/objects/#{druid}" }
  let(:toast_html) { [] }
  let(:cause) { 'process' }
  let(:error_summary) { 'accessionWF:shelve:Error: shelving failed' }
  let!(:tracked_deposit) do
    create(:tracked_deposit, druid:, version: 3, user:, process_errored_at: 1.second.ago)
  end

  let(:solr_docs) { [{ 'id' => druid, 'wf_error_ssim' => [error_summary] }] }
  let(:remedy) do
    "Retry the process from the item page, or contact SDR support at #{Settings.support_email} for assistance."
  end

  before do
    allow(Search::SolrService).to receive(:post) do
      { 'response' => { 'numFound' => solr_docs.size, 'start' => 0, 'docs' => solr_docs } }
    end
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to) do |*_args, html:, **|
      toast_html << Capybara.string(html)
    end

    # Delivers the toast and enqueues the email, without sending it.
    perform_enqueued_jobs(only: [Noticed::EventJob, DeliveryMethods::TurboToast]) do
      described_class.with(druid:, version: 3, title: 'The Gettysburg Address', cause:, error_summary:)
                     .deliver(user)
    end
  end

  def send_due_email
    perform_enqueued_jobs(only: Noticed::DeliveryMethods::Email)
  end

  it 'records an error notification about the item for the depositing user' do
    notification = user.notifications.sole
    expect(notification.record).to be_nil
    expect(notification.title).to eq('Deposit failed')
    expect(notification.subject_label).to eq('The Gettysburg Address (bc123df4567)')
    expect(notification.subject_path).to eq("/objects/#{druid}")
    expect(notification.detail).to eq("#{error_summary}. #{remedy}")
    expect(notification).to be_error
  end

  it 'broadcasts a red toast that does not disappear, linking to the item' do
    toast = toast_html.sole
    expect(toast).to have_css('.toast .bg-stanford-digital-red', text: 'Deposit failed')
    expect(toast).to have_no_css('.toast-disappear')
    expect(toast).to have_link('Version 3 of The Gettysburg Address (bc123df4567) failed to deposit.',
                               href: "/objects/#{druid}")
    expect(toast).to have_text("#{error_summary}. #{remedy}")
  end

  it 'enqueues the email for 10 minutes later' do
    expect(Noticed::DeliveryMethods::Email).to have_been_enqueued.at(be_within(5.seconds).of(10.minutes.from_now))
  end

  it 'emails the depositing user when still In Error' do
    send_due_email

    email = ActionMailer::Base.deliveries.sole
    expect(email.to).to eq([user.email_address])
    expect(email.from).to eq(['no-reply@sdr.stanford.edu'])
    expect(email.subject).to eq('SDR deposit error: “The Gettysburg Address”')
    html = Capybara.string(email.body.to_s)
    expect(html).to have_css('p', text: 'Your recent deposit for item “The Gettysburg Address” with druid ' \
                                        "bc123df4567 has failed with the error: #{error_summary}. View details " \
                                        "and address the error in Argo at #{url}.")
    expect(html).to have_link(url, href: url)
    expect(html).to have_css('p', text: "please contact the SDR team at #{Settings.support_email}.")
  end

  context 'when the Process was retried' do
    before { tracked_deposit.update!(process_errored_at: nil) }

    it 'cancels the email, keeping the notification' do
      send_due_email

      expect(ActionMailer::Base.deliveries).to be_empty
      expect(user.notifications.count).to eq(1)
    end
  end

  context 'when the Process was retried but polling has not yet seen it' do
    let(:solr_docs) { [{ 'id' => druid }] }

    it 'cancels the email, keeping the notification' do
      send_due_email

      expect(ActionMailer::Base.deliveries).to be_empty
      expect(user.notifications.count).to eq(1)
    end
  end

  context 'when the Deposit went In Error again since the Notification' do
    before { tracked_deposit.update!(process_errored_at: 1.minute.from_now) }

    it 'cancels the email, since the later error has its own' do
      send_due_email

      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  context 'when the Deposit is no longer tracked (e.g., Complete or the draft was discarded)' do
    before { tracked_deposit.destroy! }

    it 'cancels the email' do
      send_due_email

      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  context 'when staging failed' do
    let(:cause) { 'staging' }
    let(:error_summary) { "Staging failed. Contact SDR support at #{Settings.support_email} for assistance." }
    let!(:tracked_deposit) do
      create(:tracked_deposit, druid:, version: 3, user:, staging_failed_at: 1.second.ago)
    end

    it 'emails the depositing user with one period after the error' do
      send_due_email

      html = Capybara.string(ActionMailer::Base.deliveries.sole.body.to_s)
      expect(html).to have_css('p', text: "has failed with the error: #{error_summary} View details")
    end

    context 'when staging was retried' do
      before { tracked_deposit.update!(staging_failed_at: nil) }

      it 'cancels the email' do
        send_due_email

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context 'when a Process is in error instead' do
      before { tracked_deposit.update!(staging_failed_at: nil, process_errored_at: 1.second.ago) }

      it 'cancels the email, since the staging failure was left' do
        send_due_email

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end
  end
end
