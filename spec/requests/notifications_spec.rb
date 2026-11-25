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
    let(:labels) do
      ['File Check finished', 'Multi-Item Deposit settled', 'Deposit failed',
       'Bulk Action Object Deposits settled with errors', 'Deposit complete, when someone added you as a recipient']
    end

    it 'renders the email settings tab with every email on' do
      get email_settings_notifications_path

      expect(response).to have_http_status(:ok)
      rendered_page = Capybara.string(response.body)
      expect(rendered_page).to have_css('h1', exact_text: 'Notifications')
      expect(rendered_page).to have_link('Email settings', href: '/notifications/email_settings',
                                                           class: 'active')
      expect(rendered_page).to have_text("Choose which ones are also emailed to #{user.email_address}.")
      fieldset = rendered_page.find('fieldset', text: 'Email me when')
      expect(fieldset).to have_text('Emails about something you can act on are sent 10 minutes later')
      expect(fieldset.all('.form-check-label').map { |label| label.text.strip }).to eq(labels)
      labels.each { |label| expect(fieldset).to have_checked_field(label) }
      help_text_id = fieldset.find_field('File Check finished')['aria-describedby']
      expect(fieldset).to have_css("##{help_text_id}", text: 'A Multi-Item Deposit you started has finished File ' \
                                                             'Check, with or without errors.')
      expect(rendered_page).to have_button('Save')
      expect(rendered_page).to have_no_link('Cancel')
    end

    it 'shows the emails the user turned off as unchecked' do
      EmailOptOut.create!(user:, notifier_kind: 'deposit_failed')

      get email_settings_notifications_path

      rendered_page = Capybara.string(response.body)
      expect(rendered_page).to have_unchecked_field('Deposit failed')
      expect(rendered_page).to have_checked_field('File Check finished')
    end
  end

  describe 'PATCH /notifications/email_settings' do
    let(:email_settings) do
      { file_check_finished: '1', multi_item_deposit_settled: '0', deposit_failed: '0',
        bulk_action_object_deposits_settled_with_errors: '1', deposit_complete: '1' }
    end

    before { EmailOptOut.create!(user:, notifier_kind: 'file_check_finished') }

    it 'stores an opt-out for each email turned off, and none for those turned on' do
      patch email_settings_notifications_path, params: { email_settings: }

      expect(response).to redirect_to('/notifications/email_settings')
      expect(response).to have_http_status(:see_other)
      expect(flash[:toast]).to eq('Email settings saved.')
      expect(user.email_opt_outs.pluck(:notifier_kind)).to contain_exactly('multi_item_deposit_settled',
                                                                           'deposit_failed')
    end

    it "leaves other users' opt-outs alone" do
      other_user = create(:user)
      EmailOptOut.create!(user: other_user, notifier_kind: 'deposit_complete')

      patch email_settings_notifications_path, params: { email_settings: }

      expect(other_user.email_opt_outs.pluck(:notifier_kind)).to eq(['deposit_complete'])
    end
  end
end
