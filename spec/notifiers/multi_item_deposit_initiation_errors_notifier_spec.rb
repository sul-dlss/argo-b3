# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MultiItemDepositInitiationErrorsNotifier do
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

  context 'with errors' do
    before { deliver(2) }

    it 'records a notification for the owner' do
      notification = user.notifications.sole
      expect(notification.record).to eq(multi_item_deposit_action)
      expect(notification.title).to eq('Deposit Initiation found errors')
    end

    it 'broadcasts a red toast that does not disappear, linking to the Multi-Item Deposit' do
      toast = toast_html.sole
      expect(toast).to have_css('.toast .bg-stanford-digital-red', text: 'Deposit Initiation found errors')
      expect(toast).to have_no_css('.toast-disappear')
      expect(toast).to have_link('Nothing in Multi-item deposit 1 was deposited because 2 items have errors.',
                                 href: path)
    end
  end

  context 'with a single error' do
    before { deliver(1) }

    it 'renders the text for one error' do
      expect(toast_html.sole)
        .to have_link('Nothing in Multi-item deposit 1 was deposited because 1 item has errors.')
    end
  end
end
