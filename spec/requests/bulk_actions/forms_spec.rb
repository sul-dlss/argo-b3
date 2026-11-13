# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Bulk action forms' do
  let(:user) { create(:user) }
  let(:rendered_page) { Capybara.string(response.body) }
  let(:druids) { ['druid:pj757vx3102', 'druid:rt276nw8963'] }

  before do
    sign_in(user)
  end

  BulkActions.all.select(&:routable?).reject(&:admin_policy_rule).each do |config|
    describe "GET new for #{config.label}" do
      it 'renders the bulk action form' do
        get config.new_path

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('h1', text: config.label)
        expect(rendered_page).to have_title("#{config.label} | Argo B3", exact: true)
        expect(rendered_page).to have_css("form[action='#{config.create_path}']")
        expect(rendered_page).to have_field('Describe this bulk action')
        if config.form <= BulkActions::BasicCsvForm
          expect(rendered_page).to have_field('Upload a CSV or Excel file')
        else
          expect(rendered_page).to have_field('Enter druid list')
        end
        if config.close_version?
          expect(rendered_page).to have_field('Deposit objects once action is complete', checked: true)
        else
          expect(rendered_page).to have_no_field('Deposit objects once action is complete')
        end
      end
    end
  end

  BulkActions.all.select { |config| config.form == BulkActions::BasicForm }.each do |config|
    describe "POST create for #{config.label}" do
      let(:form_params) do
        { source: 'druids', druid_list: druids.join("\n"), description: "#{config.label} test items",
          close_version: '0' }
      end
      let(:expected_job_params) { config.close_version? ? { druids:, close_version: false } : { druids: } }

      it 'creates the bulk action and enqueues the job' do
        post config.create_path, params: { bulk_actions_basic: form_params }

        expect(response).to redirect_to(bulk_actions_path)
        expect(flash[:toast]).to eq("#{config.label} submitted")

        bulk_action = BulkAction.last
        expect(bulk_action.action_type).to eq(config.action_type)
        expect(bulk_action.description).to eq("#{config.label} test items")
        expect(bulk_action.user).to eq(user)
        expect(bulk_action.queued?).to be true

        expect(config.job).to have_been_enqueued.with(bulk_action:, **expected_job_params)
      end
    end
  end

  describe 'POST create without druids' do
    it 'renders the form with the error and does not create the bulk action' do
      post bulk_actions_reindex_path, params: { bulk_actions_basic: { source: 'druids', druid_list: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(rendered_page).to have_css('h1', text: 'Reindex')
      expect(rendered_page).to have_invalid_feedback('Enter druid list', "can't be blank")
      expect(BulkAction.count).to eq(0)
    end
  end

  describe 'bulk actions limited by an AdminPolicy rule' do
    let(:csv_file) { fixture_file_upload('import_read_unrestricted_workgroups.csv', 'text/csv') }
    let(:form_params) do
      { bulk_actions_import_read_unrestricted_workgroups: { csv_file:, description: 'Update workgroups' } }
    end

    context 'when signed in as an admin user' do
      let(:user) { create(:user, :admin) }

      it 'allows access to the new page' do
        get new_bulk_actions_import_read_restricted_and_edit_permissions_path

        expect(response).to have_http_status(:ok)
      end

      it 'creates the bulk action and enqueues the job' do
        post bulk_actions_import_read_unrestricted_workgroups_path, params: form_params

        expect(response).to redirect_to(bulk_actions_path)
        bulk_action = BulkAction.last
        expect(bulk_action.action_type).to eq('IMPORT_READ_UNRESTRICTED_WORKGROUPS')
        expect(BulkActions::ImportReadUnrestrictedWorkgroupsJob)
          .to have_been_enqueued.with(bulk_action:, csv_file: an_instance_of(String))
      end
    end

    context 'when signed in as a non-admin user' do
      %i[import_read_restricted_and_edit_permissions import_read_unrestricted_workgroups].each do |key|
        it "does not allow access to the #{key} new page" do
          get public_send(:"new_bulk_actions_#{key}_path")

          expect(response).to be_unauthorized
        end
      end

      it 'does not create the bulk action' do
        post bulk_actions_import_read_unrestricted_workgroups_path, params: form_params

        expect(response).to be_unauthorized
        expect(BulkAction.count).to eq(0)
      end
    end
  end
end
