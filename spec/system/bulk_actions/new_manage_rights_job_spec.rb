# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create a new manage rights bulk action' do
  let!(:user) { create(:user) }

  let(:druids) do
    ['druid:pj757vx3102', 'druid:rt276nw8963']
  end

  let(:bulk_action_label) { BulkActions::MANAGE_RIGHTS.label }

  before do
    sign_in user
  end

  it 'manages access rights and submits bulk action' do
    visit new_bulk_action_path
    click_link bulk_action_label

    expect(page).to have_css('h1', text: bulk_action_label)

    # When world view is selected, all download options are enabled
    choose_view_right 'World'
    expect_download_rights_enabled ['World', 'Stanford', 'Location Based', 'None']

    # When dark view is selected, only none download is enabled and selected
    choose_view_right 'Dark'
    expect_download_rights_enabled ['None']
    within_fieldset('Download rights') { expect(page).to have_checked_field('None') }

    # When citation-only view is selected, only none download is enabled and selected
    choose_view_right 'Citation Only'
    expect_download_rights_enabled ['None']
    within_fieldset('Download rights') { expect(page).to have_checked_field('None') }

    # When stanford view is selected, stanford and location-based download are enabled
    choose_view_right 'Stanford'
    expect_download_rights_enabled ['Stanford', 'Location Based', 'None']

    # When location-based view is selected, location-based and none download are enabled
    choose_view_right 'Location Based'
    expect_download_rights_enabled ['Location Based', 'None']

    # When location-based view is enabled, locations are enabled
    expect_locations_enabled

    # Select a location and switch back to world view with none download
    within_fieldset('Location') { choose 'Spec' }
    choose_view_right 'World'
    choose_download_right 'None'

    # Locations are disabled (but previously selected location can remain checked)
    expect_locations_disabled

    # When location-based download is selected, locations are enabled again
    choose_download_right 'Location Based'
    expect_locations_enabled

    # Submit the bulk action
    fill_in 'Enter druid list', with: druids.join("\n")
    fill_in 'Describe this bulk action', with: 'Manage rights for test items'
    expect(page).to have_checked_field('Close version once action is complete')
    click_button 'Submit'

    expect(page).to have_current_path(bulk_actions_path)
    expect(page).to have_toast("#{bulk_action_label} submitted")

    bulk_action = BulkAction.last
    expect(bulk_action.action_type).to eq(BulkActions::MANAGE_RIGHTS.action_type.to_s)
    expect(bulk_action.description).to eq('Manage rights for test items')
    expect(bulk_action.user).to eq(user)
    expect(bulk_action.queued?).to be true

    expect(BulkActions::ManageRightsJob).to have_been_enqueued.with(
      druids:,
      bulk_action:,
      close_version: true,
      view: 'world',
      download: 'location-based',
      location: 'spec'
    )
  end

  def choose_view_right(label)
    within_fieldset('View rights') { choose label }
  end

  def choose_download_right(label)
    within_fieldset('Download rights') { choose label }
  end

  def expect_download_rights_enabled(enabled_labels)
    all_download_options = {
      'World' => 'world',
      'Stanford' => 'stanford',
      'Location Based' => 'location-based',
      'None' => 'none'
    }

    within_fieldset('Download rights') do
      all_download_options.each do |label, value|
        selector = "input[name='bulk_actions_manage_rights_form[download]'][value='#{value}']"
        if enabled_labels.include?(label)
          expect(page).to have_css("#{selector}:not([disabled])")
        else
          expect(page).to have_css("#{selector}[disabled]")
        end
      end
    end
  end

  def expect_locations_enabled
    expect(page).to have_no_css('input[name="bulk_actions_manage_rights_form[location]"][disabled]')
  end

  def expect_locations_disabled
    expect(page).to have_css('input[name="bulk_actions_manage_rights_form[location]"][disabled]', count: Constants::ACCESS_LOCATIONS.length)
  end
end
