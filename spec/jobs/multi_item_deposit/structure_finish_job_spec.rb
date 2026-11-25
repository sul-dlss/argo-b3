# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDeposit::StructureFinishJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.new }

  let(:user) { create(:user) }
  let(:multi_item_deposit_action) do
    create(:multi_item_deposit_action, user:, step: 'structure', structuring_state: 'structuring',
                                       structuring_started_at: 1.minute.ago)
  end

  before do
    create(:item_deposit_action, multi_item_deposit_action:)
    create(:item_deposit_action, multi_item_deposit_action:, content_type_structure_errors: ['Bad structure'])
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
  end

  it 'completes File Check and notifies the owner of the errors' do
    job.perform(multi_item_deposit_action:)

    expect(multi_item_deposit_action.reload).to have_attributes(
      structuring_state: 'structuring_not_in_progress',
      structuring_completed_at: be_within(1.second).of(Time.current)
    )
    notification = user.notifications.sole
    expect(notification).to be_a(MultiItemDepositFileCheckFinishedNotifier::Notification)
    expect(notification.record).to eq(multi_item_deposit_action)
    expect(notification.params).to eq(name: multi_item_deposit_action.name, error_count: 1, item_deposit_count: 2)
  end

  it 'broadcasts a toast to the owner once the notification is delivered' do
    perform_enqueued_jobs(only: [Noticed::EventJob, DeliveryMethods::TurboToast]) do
      job.perform(multi_item_deposit_action:)
    end

    expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
      .with('notifications', user, target: 'toast-container', html: include('File Check finished with errors'))
  end

  it 'emails the owner 10 minutes later' do
    perform_enqueued_jobs(only: Noticed::EventJob) { job.perform(multi_item_deposit_action:) }

    expect(Noticed::DeliveryMethods::Email).to have_been_enqueued
      .at(be_within(5.seconds).of(10.minutes.from_now))
  end
end
