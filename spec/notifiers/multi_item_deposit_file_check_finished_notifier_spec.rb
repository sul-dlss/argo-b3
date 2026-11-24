# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDepositFileCheckFinishedNotifier do
  include ActiveJob::TestHelper

  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, step: 'structure', description: 'Maps', structuring_started_at: 1.minute.ago,
                                       structuring_completed_at: Time.current)
  end
  let(:user) { multi_item_deposit_action.user }
  let(:path) { "/multi_item_deposit_actions/#{multi_item_deposit_action.id}" }
  let(:url) { "http://example.com#{path}" }
  let(:toast_html) { [] }
  let(:item_deposit_count) { 3 }

  before do
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567')
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:gh456jk7890')
    create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:mn789pq0123')
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to) do |*_args, html:, **|
      toast_html << Capybara.string(html)
    end
  end

  # Delivers the toast and enqueues the email, without sending it.
  def notify(error_count)
    perform_enqueued_jobs(only: [Noticed::EventJob, DeliveryMethods::TurboToast]) do
      described_class.with(record: multi_item_deposit_action, name: multi_item_deposit_action.name, error_count:,
                           item_deposit_count:).deliver(user)
    end
  end

  def send_due_email
    perform_enqueued_jobs(only: Noticed::DeliveryMethods::Email)
  end

  def email
    ActionMailer::Base.deliveries.sole
  end

  context 'without errors' do
    before { notify(0) }

    it 'records a notification for the owner' do
      notification = user.notifications.sole
      expect(notification.record).to eq(multi_item_deposit_action)
      expect(notification.title).to eq('File Check finished')
      expect(notification.subject_label).to eq(multi_item_deposit_action.name)
      expect(notification.subject_path).to eq(path)
      expect(notification.detail).to be_nil
    end

    it 'broadcasts a disappearing toast linking to the Multi-Item Deposit' do
      toast = toast_html.sole
      expect(toast).to have_css('.toast.toast-disappear', text: 'File Check finished')
      expect(toast).to have_link("File Check completed for #{multi_item_deposit_action.name}.", href: path)
    end

    it 'enqueues the email for 10 minutes later' do
      expect(Noticed::DeliveryMethods::Email).to have_been_enqueued.at(be_within(5.seconds).of(10.minutes.from_now))
    end

    it 'emails the owner, with the footer' do
      send_due_email

      id = multi_item_deposit_action.id
      expect(email.to).to eq([user.email_address])
      expect(email.from).to eq(['no-reply@sdr.stanford.edu'])
      expect(email.reply_to).to be_nil
      expect(email.subject).to eq("Maps SDR multi-item deposit #{id} file check complete")
      expect(email.text_part.body.to_s).to include(
        "Your SDR multi-item deposit #{id} (Maps) has successfully passed its file check. " \
        "View details and complete the deposit in Argo at #{url}.",
        "If you have questions, please contact the SDR team at #{Settings.support_email}."
      )
      html = Capybara.string(email.html_part.body.to_s)
      expect(html).to have_link(url, href: url)
      expect(html).to have_link(Settings.support_email, href: "mailto:#{Settings.support_email}")
    end
  end

  context 'with errors' do
    before do
      multi_item_deposit_action.item_deposit_actions.find_by(druid: 'druid:gh456jk7890')
                               .update!(structural_csv_errors: ['No rows'],
                                        content_type_structure_errors: ['Bad structure'])
      notify(1)
    end

    it 'broadcasts a red toast that does not disappear, linking to the Multi-Item Deposit' do
      toast = toast_html.sole
      expect(toast).to have_css('.toast .bg-stanford-digital-red', text: 'File Check finished with errors')
      expect(toast).to have_no_css('.toast-disappear')
      expect(toast).to have_link("File Check found errors in 1 item of #{multi_item_deposit_action.name}.",
                                 href: path)
    end

    it 'summarizes the errors in the detail' do
      expect(user.notifications.sole.detail).to eq('1 item has errors.')
    end

    it 'emails the owner the errors' do
      send_due_email

      expect(email.subject).to eq("Maps SDR multi-item deposit #{multi_item_deposit_action.id} file check errors")
      expect(email.text_part.body.to_s).to include('has completed its file check with errors.',
                                                   "Errors found:\n- gh456jk7890: No rows\n- " \
                                                   'gh456jk7890: Bad structure')
      expect(Capybara.string(email.html_part.body.to_s)).to have_css('li', text: 'gh456jk7890: Bad structure')
    end
  end

  context 'with more errors than are listed' do
    before do
      stub_const('NotificationMailer::MAX_LISTED_ERRORS', 1)
      multi_item_deposit_action.item_deposit_actions.update_all(structural_csv_errors: ['No rows']) # rubocop:disable Rails/SkipsModelValidations
      notify(3)
      send_due_email
    end

    it 'lists only the first errors and says how many more there are' do
      expect(email.text_part.body.to_s).to include("- bc123df4567: No rows\nAnd 2 more errors")
      expect(email.text_part.body.to_s).not_to include('gh456jk7890')
    end
  end

  context 'without a description' do
    before do
      multi_item_deposit_action.update!(description: nil)
      notify(0)
      send_due_email
    end

    it 'leaves the description out of the email' do
      id = multi_item_deposit_action.id
      expect(email.subject).to eq("SDR multi-item deposit #{id} file check complete")
      expect(email.text_part.body.to_s).to include("Your SDR multi-item deposit #{id} has successfully passed")
    end
  end

  describe 'cancelling the email' do
    before { notify(0) }

    it 'sends the email if the Multi-Item Deposit has not changed' do
      expect { send_due_email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'sends the email if the owner moved to another step without running one' do
      multi_item_deposit_action.update!(step: 'deposit')

      expect { send_due_email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'cancels the email if Deposit Initiation started' do
      multi_item_deposit_action.update!(step: 'deposit', initiating_deposit_started_at: 1.second.from_now)

      expect { send_due_email }.not_to(change { ActionMailer::Base.deliveries.count })
    end

    it 'cancels the email if Deposit Initiation started, even after returning to File Check' do
      multi_item_deposit_action.update!(initiating_deposit_started_at: 1.second.from_now)

      expect { send_due_email }.not_to(change { ActionMailer::Base.deliveries.count })
    end

    it 'cancels the email if File Check was re-run' do
      multi_item_deposit_action.update!(structuring_started_at: 1.second.from_now, structuring_completed_at: nil)

      expect { send_due_email }.not_to(change { ActionMailer::Base.deliveries.count })
    end

    it 'cancels the email if Discovery was re-run' do
      multi_item_deposit_action.update!(step: 'discovery', structuring_started_at: nil)

      expect { send_due_email }.not_to(change { ActionMailer::Base.deliveries.count })
    end

    it 'cancels the email if a MID Item Deposit was removed' do
      multi_item_deposit_action.item_deposit_actions.first.destroy!

      expect { send_due_email }.not_to(change { ActionMailer::Base.deliveries.count })
    end

    it 'cancels the email if the Multi-Item Deposit was deleted, discarding the job' do
      multi_item_deposit_action.discard!

      expect { send_due_email }.not_to(change { ActionMailer::Base.deliveries.count })
      expect(Noticed::DeliveryMethods::Email).not_to have_been_enqueued
    end

    it 'leaves the notification in place when the email is cancelled' do
      multi_item_deposit_action.update!(structuring_started_at: 1.second.from_now)
      send_due_email

      expect(user.notifications.count).to eq(1)
    end
  end
end
