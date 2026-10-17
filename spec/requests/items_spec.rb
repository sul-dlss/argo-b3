# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Items' do
  let(:user) { create(:user, :reader) }

  describe 'create' do
    context 'when invalid' do
      before do
        allow(Searchers::AdminPolicyList).to receive(:call).and_return([['My APO', 'druid:hv992ry2431']])
        allow(Searchers::CollectionListByDruid).to receive(:call)
          .and_return([['Art History Slides', 'druid:bc123df4567']])
        sign_in(user)
      end

      it 'renders the selected collections, labeling those not found with the bare druid' do
        # No title is provided, so the item is invalid.
        post '/items', params: { item: { collection_druids: ['', 'druid:bc123df4567', 'druid:xz987wv6543'] } }

        expect(response).to have_http_status(:unprocessable_content)
        page = Capybara.string(response.body)
        expect(page).to have_select('Collections', visible: :all, selected: ['Art History Slides', 'xz987wv6543'])
        expect(Searchers::CollectionListByDruid).to have_received(:call)
          .with(druids: %w[druid:bc123df4567 druid:xz987wv6543])
      end
    end
  end

  describe 'edit' do
    let(:druid) { 'druid:bc123df4567' }
    let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book) }
    let(:version_service) do
      version_service_double(open?: open, editable?: true, version_description: 'Fixing the title')
    end

    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
      allow(Sdr::VersionService).to receive(:new).and_return(version_service)
      allow(Searchers::AdminPolicyList).to receive(:call).and_return([])
      allow(Searchers::CollectionListByDruid).to receive(:call).and_return([])
      allow(Searchers::AdminPolicyListByDruid).to receive(:call).and_return([])
      sign_in(user)
    end

    context 'when the version is open' do
      let(:open) { true }

      it 'prefills the version description from the open version' do
        get "/items/#{druid}/edit"

        expect(response).to have_http_status(:ok)
        expect(Capybara.string(response.body)).to have_field('Version description', with: 'Fixing the title')
        expect(Sdr::VersionService).to have_received(:new).with(druid:).once
      end

      it 'renders the save as draft and deposit buttons' do
        get "/items/#{druid}/edit"

        expect(Capybara.string(response.body)).to have_button('Save as draft', count: 4)
        expect(Capybara.string(response.body)).to have_button('Deposit', type: 'submit', count: 1)
      end

      it 'renders the lock as a hidden field' do
        get "/items/#{druid}/edit"

        expect(Capybara.string(response.body)).to have_field('item[lock]', type: :hidden, with: cocina_object.lock)
      end
    end

    context 'when rendering the rights' do
      let(:open) { true }
      let(:cocina_object) do
        build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book)
          .then { |dro| dro.new(access: dro.access.to_h.merge(license: Constants::LICENSE_OPTIONS.first[:uri])) }
      end

      it 'renders the rights fields with the current values' do
        get "/items/#{druid}/edit"

        page = Capybara.string(response.body)
        expect(page).to have_select('License', selected: Constants::LICENSE_OPTIONS.first[:label])
        expect(page).to have_field('Copyright')
        expect(page).to have_field('Use and reproduction')
        expect(page).to have_field('Without embargo', type: 'radio', checked: true)
      end

      context 'when the user can select the current APO' do
        before do
          allow(Searchers::AdminPolicyList).to receive(:call)
            .and_return([['My APO', cocina_object.administrative.hasAdminPolicy]])
        end

        it 'selects the APO by title' do
          get "/items/#{druid}/edit"

          expect(Capybara.string(response.body)).to have_select('APO', selected: 'My APO', options: ['My APO'])
        end
      end

      context 'when the user cannot otherwise select the current APO' do
        let(:apo_druid) { cocina_object.administrative.hasAdminPolicy }

        before do
          allow(Searchers::AdminPolicyListByDruid).to receive(:call).and_return([['Restricted APO', apo_druid]])
        end

        it 'adds the APO as an option labeled with its title' do
          get "/items/#{druid}/edit"

          expect(Capybara.string(response.body)).to have_select('APO', selected: 'Restricted APO')
          expect(Searchers::AdminPolicyListByDruid).to have_received(:call).with(druids: ['druid:hv992ry2431'])
        end
      end

      context 'when the current APO is not found' do
        it 'adds the APO as an option labeled with its druid' do
          get "/items/#{druid}/edit"

          expect(Capybara.string(response.body)).to have_select('APO', selected: 'hv992ry2431')
        end
      end
    end

    context 'when the version is closed' do
      let(:open) { false }

      it 'renders an empty version description' do
        get "/items/#{druid}/edit"

        expect(response).to have_http_status(:ok)
        expect(Capybara.string(response.body).find_field('Version description').value).to be_blank
      end
    end
  end

  describe 'update' do
    let(:druid) { 'druid:bc123df4567' }
    let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book) }
    let(:opened_cocina_object) { cocina_object.new(version: 2, lock: 'opened-lock') }
    let(:version_service) do
      version_service_double(open?: open, editable?: editable, version_description: 'Changed type')
    end
    let(:open) { true }
    let(:editable) { true }
    let(:item_params) do
      { content_type: Cocina::Models::ObjectType.image, version_description: 'Changed type', lock: cocina_object.lock }
    end
    let(:commit) { ItemsController::DRAFT_VALUE }

    before do
      create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
      allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object }
      allow(Sdr::VersionService).to receive_messages(new: version_service, open: opened_cocina_object)
      allow(Sdr::Repository).to receive(:accession)
      sign_in(user)
    end

    context 'when the version is open' do
      it 'saves without opening a new version' do
        patch "/items/#{druid}", params: { item: item_params, commit: }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Item updated.')
        expect(Sdr::VersionService).to have_received(:new).with(druid:).once
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(Sdr::Repository).to have_received(:update)
          .with(cocina_object: having_attributes(type: Cocina::Models::ObjectType.image, lock: cocina_object.lock),
                user_name: user.sunetid, description: nil)
        expect(Sdr::Repository).not_to have_received(:accession)
        expect(version_service).not_to have_received(:update_description)
      end
    end

    context 'when saving as a draft with an open version and a changed version description' do
      let(:item_params) { { version_description: 'Changed type and title', lock: cocina_object.lock } }

      it 'updates the version description' do
        patch "/items/#{druid}", params: { item: item_params, commit: }

        expect(response).to redirect_to(object_path(druid))
        expect(version_service).to have_received(:update_description)
          .with(description: 'Changed type and title', user_name: user.sunetid)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when depositing with an open version and a changed version description' do
      let(:commit) { ItemsController::DEPOSIT_VALUE }
      let(:item_params) { { version_description: 'Changed type and title', lock: cocina_object.lock } }

      it 'updates the version description before accessioning' do
        patch "/items/#{druid}", params: { item: item_params, commit: }

        expect(version_service).to have_received(:update_description)
          .with(description: 'Changed type and title', user_name: user.sunetid).ordered
        expect(Sdr::Repository).to have_received(:accession).ordered
      end
    end

    context 'when the rights changed' do
      let(:item_params) do
        { license: Constants::LICENSE_OPTIONS.first[:uri], copyright: 'Copyright © Stanford University.',
          with_embargo: 'false', limit_collection_by_apo: '1', collection_druids: [''],
          version_description: 'Changed type', lock: cocina_object.lock }
      end

      it 'saves the rights' do
        patch "/items/#{druid}", params: { item: item_params, commit: }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::Repository).to have_received(:update)
          .with(cocina_object: having_attributes(access: having_attributes(
            license: Constants::LICENSE_OPTIONS.first[:uri], copyright: 'Copyright © Stanford University.'
          )), user_name: user.sunetid, description: nil)
      end
    end

    context 'when only the attributes that control the form are submitted' do
      let(:item_params) do
        { with_embargo: 'false', limit_collection_by_apo: '1', collection_druids: [''],
          version_description: 'Changed type', lock: cocina_object.lock }
      end

      it 'does not save' do
        patch "/items/#{druid}", params: { item: item_params, commit: }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when depositing with an open version' do
      let(:commit) { ItemsController::DEPOSIT_VALUE }

      it 'saves and then starts accessioning the saved object' do
        patch "/items/#{druid}", params: { item: item_params, commit: }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('Item updated and deposit started.')
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(Sdr::Repository).to have_received(:update).ordered
        expect(Sdr::Repository).to have_received(:accession)
          .with(cocina_object: having_attributes(type: Cocina::Models::ObjectType.image), user_name: user.sunetid)
          .ordered
      end
    end

    context 'when depositing with a closed version and nothing changed' do
      let(:open) { false }
      let(:commit) { ItemsController::DEPOSIT_VALUE }
      let(:item_params) { { version_description: 'Redeposit', lock: cocina_object.lock } }

      it 'opens a new version and starts accessioning it without saving' do
        patch "/items/#{druid}", params: { item: item_params, commit: }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::VersionService).to have_received(:open)
          .with(druid:, description: 'Redeposit', opening_user_name: user.sunetid)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(Sdr::Repository).to have_received(:accession)
          .with(cocina_object: opened_cocina_object, user_name: user.sunetid)
      end
    end

    context 'when the version is closed and there is a version description' do
      let(:open) { false }

      it 'opens a new version and saves against it' do
        patch "/items/#{druid}", params: { item: item_params, commit: }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::VersionService).to have_received(:open)
          .with(druid:, description: 'Changed type', opening_user_name: user.sunetid)
        expect(version_service).not_to have_received(:update_description)
        expect(Sdr::Repository).to have_received(:update)
          .with(cocina_object: having_attributes(type: Cocina::Models::ObjectType.image, version: 2,
                                                 lock: 'opened-lock'),
                user_name: user.sunetid, description: nil)
      end
    end

    context 'when there is no version description' do
      let(:item_params) do
        { content_type: Cocina::Models::ObjectType.image, version_description: '', lock: cocina_object.lock }
      end

      before do
        allow(Searchers::AdminPolicyList).to receive(:call).and_return([])
        allow(Searchers::CollectionListByDruid).to receive(:call).and_return([])
        allow(Searchers::AdminPolicyListByDruid).to receive(:call).and_return([])
      end

      it 'renders the edit page without saving' do
        patch "/items/#{druid}", params: { item: item_params, commit: }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Capybara.string(response.body)).to have_field('Version description')
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the version is closed and nothing changed' do
      let(:open) { false }
      let(:item_params) { { version_description: 'Nothing really', lock: cocina_object.lock } }

      it 'neither opens a version nor saves' do
        patch "/items/#{druid}", params: { item: item_params, commit: }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(Sdr::Repository).not_to have_received(:update)
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when the item was changed after the edit page was loaded' do
      let(:open) { false }
      let(:item_params) do
        { content_type: Cocina::Models::ObjectType.image, version_description: 'Changed type', lock: 'stale-lock' }
      end

      it 'redirects to the edit page with a warning without saving' do
        patch "/items/#{druid}", params: { item: item_params, commit: }

        expect(response).to redirect_to(edit_item_path(druid))
        expect(flash[:warning]).to eq('This item was changed since you opened it. ' \
                                      'Review the current values and make your changes again.')
        expect(Sdr::VersionService).not_to have_received(:open)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the version is not editable' do
      let(:open) { false }
      let(:editable) { false }

      it 'redirects to the object page with a warning' do
        patch "/items/#{druid}", params: { item: item_params, commit: }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq('Item is not editable.')
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the user cannot edit the item' do
      before { Permission.permission_type_edit.destroy_all }

      it 'denies access without saving' do
        patch "/items/#{druid}", params: { item: item_params, commit: }

        expect(response).to redirect_to(root_path)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end
  end
end
