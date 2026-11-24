# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DepositCompleteNotifier do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:toast_html) { [] }

  before do
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to) do |*_args, html:, **|
      toast_html << Capybara.string(html)
    end

    perform_enqueued_jobs do
      described_class.with(druid: 'druid:bc123df4567', version: 3, title: 'The Gettysburg Address').deliver(user)
    end
  end

  it 'records a notification about the item for the depositing user' do
    notification = user.notifications.sole
    expect(notification.record).to be_nil
    expect(notification.title).to eq('Deposit complete')
    expect(notification.subject_label).to eq('The Gettysburg Address (bc123df4567)')
    expect(notification.subject_path).to eq('/objects/druid:bc123df4567')
    expect(notification.detail).to eq('Version 3 was deposited.')
    expect(notification).not_to be_error
  end

  it 'broadcasts a disappearing toast linking to the item' do
    toast = toast_html.sole
    expect(toast).to have_css('.toast', text: 'Deposit complete')
    expect(toast).to have_css('.toast-disappear')
    expect(toast).to have_link('Version 3 of The Gettysburg Address (bc123df4567) was deposited.',
                               href: '/objects/druid:bc123df4567')
  end
end
