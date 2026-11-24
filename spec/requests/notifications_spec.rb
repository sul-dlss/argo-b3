# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Notifications' do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET /notifications' do
    let(:bulk_action) { create(:bulk_action, user:) }

    after { bulk_action.remove_output_directory! }

    # Noticed timestamps notifications in the database, ignoring travel_to, so created_at is set here.
    def notify(user, label:, created_at: Time.current)
      BulkActionFinishedNotifier.with(record: bulk_action, label:, failure_count: 0).deliver(user)
                                .notifications.update_all(created_at:) # rubocop:disable Rails/SkipsModelValidations
    end

    it 'lists the most recent notifications within the retention period, newest first' do
      notify(user, label: 'Expired', created_at: 31.days.ago)
      26.times { |index| notify(user, label: "Action #{index}", created_at: (26 - index).hours.ago) }

      get notifications_path

      expect(response).to have_http_status(:ok)
      rendered_page = Capybara.string(response.body)
      expect(rendered_page).to have_title('Notifications | Argo B3', exact: true)
      expect(rendered_page).to have_css('h1', exact_text: 'Notifications')
      expect(rendered_page).to have_link('Recent', href: '/notifications', class: 'active')
      expect(rendered_page).to have_link('Email settings', href: '/notifications/email_settings')
      links = rendered_page.all('#notifications-table tbody a').map(&:text)
      expect(links).to eq((1..25).map { |index| "Action #{index}" }.reverse)
    end

    it "lists only the current user's notifications" do
      notify(create(:user), label: 'Other user')

      get notifications_path

      expect(Capybara.string(response.body)).to have_text('No notifications.')
    end

    it 'lists a notification without a record, about an item' do
      DepositCompleteNotifier.with(druid: 'druid:bc123df4567', version: 2, title: 'The Gettysburg Address')
                             .deliver(user)

      get notifications_path

      rendered_page = Capybara.string(response.body)
      expect(rendered_page).to have_link('The Gettysburg Address (bc123df4567)', href: '/objects/druid:bc123df4567')
      expect(rendered_page).to have_text('Version 2 was deposited.')
    end

    context 'when an admin is impersonating' do
      let(:user) { create(:user, :admin, groups: [AuthenticationHelpers::ADMIN_GROUP]) }

      before do
        notify(user, label: 'Own')
        patch admin_impersonate_path, params: { impersonation: { workgroups: ['sdr:map-staff'] } }
      end

      it 'lists their own notifications' do
        get notifications_path

        expect(Capybara.string(response.body)).to have_link('Own', href: "/bulk_actions/#{bulk_action.id}")
      end
    end
  end

  describe 'GET /notifications/email_settings' do
    it 'renders the email settings tab' do
      get email_settings_notifications_path

      expect(response).to have_http_status(:ok)
      rendered_page = Capybara.string(response.body)
      expect(rendered_page).to have_css('h1', exact_text: 'Notifications')
      expect(rendered_page).to have_link('Email settings', href: '/notifications/email_settings',
                                                           class: 'active')
    end
  end
end
