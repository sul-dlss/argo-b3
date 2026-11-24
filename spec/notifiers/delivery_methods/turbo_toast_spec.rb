# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeliveryMethods::TurboToast do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:toast_html) { [] }

  before do
    notifier_class = Class.new(ApplicationNotifier) do
      deliver_by :turbo_toast, class: 'DeliveryMethods::TurboToast'

      notification_methods do
        def title = 'Something happened'
        def text = subject_link('See it', '/somewhere')
      end
    end
    stub_const('TestNotifier', notifier_class)

    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to) do |*_args, html:, **|
      toast_html << Capybara.string(html)
    end
  end

  context 'when the notification does not report an error' do
    it 'broadcasts a disappearing toast to the recipient' do
      perform_enqueued_jobs { TestNotifier.deliver(user) }

      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
        .with('notifications', user, target: 'toast-container', html: kind_of(String))
      toast = toast_html.sole
      expect(toast).to have_css('.toast.toast-disappear', text: 'Something happened')
      expect(toast).to have_link('See it', href: '/somewhere')
    end
  end
end
