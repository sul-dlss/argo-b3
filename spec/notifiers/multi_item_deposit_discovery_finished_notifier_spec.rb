# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDepositDiscoveryFinishedNotifier do
  include ActiveJob::TestHelper

  let(:multi_item_deposit_action) { create(:multi_item_deposit_action) }
  let(:user) { multi_item_deposit_action.user }
  let(:path) { "/multi_item_deposit_actions/#{multi_item_deposit_action.id}" }
  let(:toast_html) { [] }

  before do
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to) do |*_args, html:, **|
      toast_html << Capybara.string(html)
    end
  end

  def deliver(error_count)
    perform_enqueued_jobs do
      described_class.with(record: multi_item_deposit_action, name: 'Multi-item deposit 1', error_count:).deliver(user)
    end
  end

  context 'without errors' do
    before { deliver(0) }

    it 'records a notification for the owner' do
      notification = user.notifications.sole
      expect(notification.record).to eq(multi_item_deposit_action)
      expect(notification.title).to eq('Discovery finished')
    end

    it 'broadcasts a disappearing toast linking to the Multi-Item Deposit' do
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
        .with('notifications', user, target: 'toast-container', html: kind_of(String))
      toast = toast_html.sole
      expect(toast).to have_css('.toast.toast-disappear', text: 'Discovery finished')
      expect(toast).to have_link('Discovery completed for Multi-item deposit 1.', href: path)
    end
  end

  context 'with errors' do
    before { deliver(1_200) }

    it 'broadcasts a red toast that does not disappear, linking to the Multi-Item Deposit' do
      toast = toast_html.sole
      expect(toast).to have_css('.toast .bg-stanford-digital-red', text: 'Discovery finished with errors')
      expect(toast).to have_no_css('.toast-disappear')
      expect(toast).to have_link('Discovery found errors in 1,200 items of Multi-item deposit 1.', href: path)
    end
  end

  context 'with a single error' do
    before { deliver(1) }

    it 'renders the text for one error' do
      expect(toast_html.sole).to have_link('Discovery found errors in 1 item of Multi-item deposit 1.')
    end
  end
end
