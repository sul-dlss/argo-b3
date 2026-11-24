# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Multiple items' do
  let(:workgroup) { 'sdr:test-workgroup' }
  let(:user) { create(:user, groups: [workgroup]) }

  before do
    sign_in(user)
  end

  context 'when the user belongs to a workgroup with edit permission' do
    before do
      create(:permission, :edit, workgroup:, target_druid: 'druid:bc123df4567')
    end

    it 'renders the new page with only the APOs the user can edit' do
      allow(Searchers::AdminPolicyList).to receive(:call).and_return([])

      get new_multiple_item_path

      expect(response).to have_http_status(:ok)
      expect(Searchers::AdminPolicyList).to have_received(:call).with(user_scope: Permissions::UserScope,
                                                                      editable: true)
    end

    it 'labels the Goobi choice with a visible legend' do
      allow(Searchers::AdminPolicyList).to receive(:call).and_return([])

      get new_multiple_item_path

      fieldset = Capybara.string(response.body).find(:fieldset, 'Deposit with Goobi')
      expect(fieldset).to have_css('legend', text: 'Deposit with Goobi')
      expect(fieldset).to have_no_css('.visually-hidden, [aria-hidden]')
      expect(fieldset).to have_field('Yes', type: 'radio')
      expect(fieldset).to have_field('No', type: 'radio')
    end
  end

  context 'with the registration settings of an item' do
    let(:cocina_object) do
      build(:dro_with_metadata, id: 'druid:bc123df4567', type: Cocina::Models::ObjectType.image,
                                admin_policy_id: 'druid:hv992ry2431', collection_ids: ['druid:xz987wv6543'])
        .new(access: { view: 'stanford', download: 'none', copyright: 'Copyright © Stanford University.' })
    end

    before do
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
      allow(Sdr::AdministrativeTags).to receive(:list).and_return(['Project : Maps'])
      allow(Searchers::AdminPolicyList).to receive(:call).and_return([['My APO', 'druid:hv992ry2431']])
      allow(Searchers::CollectionListByDruid).to receive(:call).and_return([['My Collection', 'druid:xz987wv6543']])
      goobi_workflow = Dor::Services::Response::Workflow.new(
        xml: '<workflow id="goobiWF"><process version="1" status="completed" name="start"/></workflow>'
      )
      allow(Sdr::WorkflowService).to receive(:workflows_for).and_return([goobi_workflow])
    end

    context 'when the user can register with the item’s APO and collections' do
      before do
        create(:permission, :edit, workgroup:, target_druid: 'druid:hv992ry2431')
        create(:permission, :edit, workgroup:, target_druid: 'druid:xz987wv6543')
      end

      it 'prefills the settings without any items and keeps them from the APO defaults' do
        get new_multiple_item_path(from_druid: 'druid:bc123df4567')

        expect(response).to have_http_status(:ok)
        page = Capybara.string(response.body)
        expect(page).to have_select('items_registration[content_type]', selected: 'image')
        expect(page).to have_checked_field('items_registration[deposit_with_goobi]', with: 'true')
        expect(page).to have_select('items_registration[apo_druid]', visible: :all, selected: 'My APO')
        expect(page).to have_select('items_registration[collection_druids][]', visible: :all,
                                                                               selected: ['My Collection'])
        expect(page).to have_select('items_registration[access_view]', selected: 'Stanford')
        expect(page).to have_select('items_registration[access_download]', selected: 'None')
        expect(page).to have_field('items_registration[copyright]', with: 'Copyright © Stanford University.')
        expect(page).to have_field('items_registration[project_tags_attributes][0][tag]', with: 'Maps')
        expect(page).to have_no_css('input[name="items_registration[item_registrations_attributes][0][source_id]"]' \
                                    '[value]')
        expect(page).to have_css('[data-controller="apo-defaults"][data-apo-defaults-apply-on-connect-value="false"]')
      end
    end

    context 'when the user cannot register with the item’s collections' do
      before do
        create(:permission, :edit, workgroup:, target_druid: 'druid:hv992ry2431')
        allow(Sdr::Repository).to receive(:find_solr).and_return({ Search::Fields::ID => 'druid:xz987wv6543' })
      end

      it 'denies access' do
        get new_multiple_item_path(from_druid: 'druid:bc123df4567')

        expect(response).to redirect_to(root_path)
      end
    end
  end

  context 'when the user does not belong to a workgroup with edit permission' do
    it 'denies access' do
      get new_multiple_item_path

      expect(response).to redirect_to(root_path)
    end
  end

  context 'when the user cannot edit the selected collection' do
    before do
      create(:permission, :edit, workgroup:, target_druid: 'druid:hv992ry2431')
      allow(Sdr::Repository).to receive(:find_solr).with(druid: 'druid:bc123df4567')
                                                   .and_return({ Search::Fields::ID => 'druid:bc123df4567' })
    end

    it 'denies access' do
      post multiple_items_path, params: {
        items_registration: { apo_druid: 'druid:hv992ry2431', collection_druids: ['druid:bc123df4567'] }
      }

      expect(response).to redirect_to(root_path)
      expect(flash[:danger]).to eq 'You are not authorized to perform the requested action.'
      expect(FormValidationAction.count).to eq 0
    end
  end

  describe 'clearing the items' do
    before do
      create(:permission, :edit, workgroup:, target_druid: 'druid:bc123df4567')
      create(:permission, :edit, workgroup:, target_druid: 'druid:xz987wv6543')
      allow(Searchers::AdminPolicyList).to receive(:call).and_return([['My APO', 'druid:hv992ry2431']])
      allow(Searchers::CollectionListByDruid).to receive(:call)
        .and_return([['Art History Slides', 'druid:bc123df4567']])
    end

    it 'renders the selected collections, labeling those not found with the bare druid' do
      post multiple_items_path, params: {
        commit: MultipleItemsController::CLEAR_VALUE,
        items_registration: { collection_druids: ['', 'druid:bc123df4567', 'druid:xz987wv6543'] }
      }

      expect(response).to have_http_status(:unprocessable_content)
      page = Capybara.string(response.body)
      expect(page).to have_select('Collections', visible: :all, selected: ['Art History Slides', 'xz987wv6543'])
      expect(Searchers::CollectionListByDruid).to have_received(:call)
        .with(druids: %w[druid:bc123df4567 druid:xz987wv6543])
    end
  end

  describe 'uploading a csv_file that cannot be read' do
    before do
      create(:permission, :edit, workgroup:, target_druid: 'druid:bc123df4567')
      allow(Searchers::AdminPolicyList).to receive(:call).and_return([])
    end

    it 'renders the form with the error once the form has been validated' do
      post multiple_items_path, params: {
        items_registration: { items_choice: ItemsRegistrationForm::UPLOAD_CSV_CHOICE,
                              csv_file: fixture_file_upload('catalog_record_id_and_barcode.xls') }
      }
      form_validation_action = FormValidationAction.last
      ValidateFormJob.perform_now(form_validation_action:)

      get multiple_item_path(form_validation_action)

      expect(form_validation_action.reload).to be_status_invalid
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Unsupported upload file type')
    end
  end

  describe 'showing a form validation action' do
    let(:form_validation_action) do
      FormValidationAction.create!(user: form_validation_action_user, form: ItemsRegistrationForm.new,
                                   status: 'queued')
    end

    before do
      allow(Searchers::AdminPolicyList).to receive(:call).and_return([])
    end

    context 'when the form validation action belongs to the user' do
      let(:form_validation_action_user) { user }

      it 'renders the show page with the spinner message in a status region' do
        get multiple_item_path(form_validation_action)

        expect(response).to have_http_status(:ok)
        expect(Capybara.string(response.body)).to have_css('[role="status"]', exact_text: 'Validating...')
      end
    end

    context 'when the form validation action belongs to another user' do
      let(:form_validation_action_user) { create(:user) }

      it 'denies access' do
        get multiple_item_path(form_validation_action)

        expect(response).to be_unauthorized
      end
    end

    context 'when the form validation action is invalid' do
      let(:form_validation_action) do
        FormValidationAction.create!(user:, form: ItemsRegistrationForm.new(collection_druids: ['druid:bc123df4567']),
                                     status: 'invalid')
      end

      before do
        allow(Searchers::CollectionListByDruid).to receive(:call)
          .and_return([['Art History Slides', 'druid:bc123df4567']])
      end

      it 'renders the selected collections' do
        get multiple_item_path(form_validation_action)

        expect(response).to have_http_status(:unprocessable_content)
        page = Capybara.string(response.body)
        expect(page).to have_select('Collections', visible: :all, selected: ['Art History Slides'])
        expect(Searchers::CollectionListByDruid).to have_received(:call).with(druids: ['druid:bc123df4567'])
      end
    end

    context 'when the form validation action failed' do
      let(:form_validation_action) do
        FormValidationAction.create!(user:, form: ItemsRegistrationForm.new, status: 'failed')
      end

      it 'renders the form with an error' do
        get multiple_item_path(form_validation_action)

        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:danger]).to eq('An error occurred while validating your registrations. Please try again.')
      end
    end
  end
end
