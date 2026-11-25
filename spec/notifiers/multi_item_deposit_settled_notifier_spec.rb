# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDepositSettledNotifier do
  include ActiveJob::TestHelper

  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, step: 'submitted', description: 'Maps', settled_at: Time.current)
  end
  let(:user) { multi_item_deposit_action.user }

  before { allow(Turbo::StreamsChannel).to receive(:broadcast_append_to) }

  # Delivers the toast and enqueues the email, without sending it.
  def notify(error_count)
    perform_enqueued_jobs(only: [Noticed::EventJob, DeliveryMethods::TurboToast]) do
      described_class.with(record: multi_item_deposit_action, name: multi_item_deposit_action.name, error_count:,
                           item_deposit_count: 1_200).deliver(user)
    end
  end

  def send_due_email
    perform_enqueued_jobs(only: Noticed::DeliveryMethods::Email)
  end

  it 'enqueues the complete email immediately' do
    notify(0)

    expect(Noticed::DeliveryMethods::Email).to have_been_enqueued.at(be_within(5.seconds).of(Time.current))
  end

  it 'enqueues the with errors email for 10 minutes later, with delimited counts' do
    notify(1_100)

    expect(Noticed::DeliveryMethods::Email).to have_been_enqueued.at(be_within(5.seconds).of(10.minutes.from_now))
    notification = user.notifications.sole
    expect(notification.detail).to eq('1,100 of 1,200 items have errors.')
    expect(notification.subject_label).to eq(multi_item_deposit_action.name)
    expect(notification.subject_path).to eq("/multi_item_deposit_actions/#{multi_item_deposit_action.id}")
  end

  context 'when the email is due' do
    before { notify(1) }

    it 'sends the email and records that a settled email has gone out' do
      expect { send_due_email }.to change(ActionMailer::Base.deliveries, :count).by(1)
      expect(multi_item_deposit_action.reload.settled_email_sent_at).to be_present
    end

    it 'cancels the email if the Multi-Item Deposit is unsettled' do
      multi_item_deposit_action.update!(settled_at: nil)

      expect { send_due_email }.not_to change(ActionMailer::Base.deliveries, :count)
      expect(multi_item_deposit_action.reload.settled_email_sent_at).to be_nil
      expect(user.notifications.count).to eq(1)
    end

    it 'cancels the email if the Multi-Item Deposit has settled again since the Notification' do
      multi_item_deposit_action.update!(settled_at: 1.second.from_now)

      expect { send_due_email }.not_to change(ActionMailer::Base.deliveries, :count)
    end
  end
end
