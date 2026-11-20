# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Apply APO defaults' do
  let(:user) { create(:user, :reader) }
  let(:druid) { 'druid:bc123df4567' }
  let(:apo_druid) { 'druid:hv992ry2431' }
  let(:cocina_object) do
    build(:dro_with_metadata, id: druid, title: 'My item', admin_policy_id: apo_druid, version: 2)
      .new(access: { view: 'world', download: 'world', copyright: 'Copyright me.' })
  end
  let(:apo_cocina_object) do
    build(:admin_policy_with_metadata, id: apo_druid, title: 'My APO').new(
      administrative: { hasAdminPolicy: 'druid:hv992ry2431', hasAgreement: 'druid:hp308wm0436',
                        accessTemplate: { view: 'stanford', download: 'stanford',
                                          useAndReproductionStatement: 'Ask the library.',
                                          license: 'https://creativecommons.org/licenses/by/4.0/legalcode' } }
    )
  end
  let(:version_service) { version_service_double(open?: false, openable?: true, closeable?: false, version: 2) }
  let(:opened_cocina_object) { cocina_object.new(version: 3, lock: 'opened-lock') }
  let(:updated_cocina_object) { opened_cocina_object.new(lock: 'updated-lock') }
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    allow(Sdr::Repository).to receive(:find).with(druid:).and_return(cocina_object)
    allow(Sdr::Repository).to receive(:find).with(druid: apo_druid).and_return(apo_cocina_object)
    allow(Sdr::Repository).to receive_messages(update: updated_cocina_object, accession: nil)
    allow(Sdr::VersionService).to receive_messages(new: version_service, open: opened_cocina_object)
    sign_in(user)
  end

  describe 'new' do
    context 'when the user can edit a deposited item' do
      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'lists the defaults with the overwrite checkbox, default version description, and buttons' do
        get "/objects/#{druid}/apo_defaults/new"

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('h1', text: 'Apply APO defaults')
        expect(rendered_page).to have_text('My item')
        expect(rendered_page).to have_link('My APO', href: "/objects/#{apo_druid}")
        expect(rendered_page).to have_css('dt', text: 'View access')
        expect(rendered_page).to have_css('dd', text: 'APO default = Stanford')
        expect(rendered_page).to have_css('dt', text: 'Location')
        expect(rendered_page).to have_css('dt', text: 'Copyright')
        expect(rendered_page).to have_css('dd', text: 'APO default = none')
        expect(rendered_page).to have_css('dd', text: 'APO default = Ask the library.')
        expect(rendered_page).to have_css('dd', text: 'APO default = CC Attribution 4.0 International')
        expect(rendered_page).to have_unchecked_field('Overwrite file-level rights')
        expect(rendered_page).to have_field('Version description', with: 'Apply APO defaults')
        expect(rendered_page).to have_link('Cancel', href: "/objects/#{druid}")
        expect(rendered_page).to have_button('Apply APO defaults and save as draft')
        expect(rendered_page).to have_button('Apply APO defaults and deposit')
      end
    end

    context 'when the item has a Draft' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it "prefills the Draft's version description" do
        get "/objects/#{druid}/apo_defaults/new"

        expect(rendered_page).to have_field('Version description', with: 'Fixing the title')
      end
    end

    context 'when the Draft has unsaved changes to its files' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        content = create(:content, :mutable, druid:, lock: cocina_object.lock)
        # A file that has not been staged is an unsaved change.
        create(:content_file_binary, content:, file_location: 'attached')
      end

      it 'offers only saving as a draft, with the reason' do
        get "/objects/#{druid}/apo_defaults/new"

        expect(rendered_page).to have_button('Apply APO defaults and save as draft')
        expect(rendered_page).to have_no_button('Apply APO defaults and deposit')
        expect(rendered_page).to have_text('Files have unsaved changes. Deposit from Manage files.')
      end
    end

    context 'when the object is a collection' do
      let(:cocina_object) do
        build(:collection_with_metadata, id: druid, title: 'My collection', admin_policy_id: apo_druid)
      end

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'lists only the rights defaults and offers only depositing' do
        get "/objects/#{druid}/apo_defaults/new"

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('dt', text: 'Use and reproduction')
        expect(rendered_page).to have_no_css('dt', text: 'View access')
        expect(rendered_page).to have_no_field('Overwrite file-level rights')
        expect(rendered_page).to have_no_button('Apply APO defaults and save as draft')
        expect(rendered_page).to have_button('Apply APO defaults and deposit')
      end
    end

    context 'when the object is not editable' do
      let(:version_service) { version_service_double(version: 2, assembling?: true, closeable?: false) }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'redirects to the object page with a warning' do
        get "/objects/#{druid}/apo_defaults/new"

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq('This object is not editable.')
      end
    end

    context 'when the user cannot edit the object' do
      it 'redirects to the root' do
        get "/objects/#{druid}/apo_defaults/new"

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
      end
    end
  end

  describe 'create' do
    let(:form_params) { { version_description: 'Reset rights', overwrite_file_access: '0' } }

    context 'when depositing a deposited item' do
      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'opens a version, saves the defaults, and starts accessioning' do
        post "/objects/#{druid}/apo_defaults", params: { apo_defaults: form_params, commit: 'deposit' }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('APO defaults applied and deposit started.')
        expect(Sdr::VersionService).to have_received(:open)
          .with(druid:, description: 'Reset rights', opening_user_name: user.sunetid)
        expect(Sdr::Repository).to have_received(:update).with(
          cocina_object: an_object_having_attributes(
            version: 3,
            access: an_object_having_attributes(view: 'stanford', download: 'stanford', copyright: nil,
                                                useAndReproductionStatement: 'Ask the library.')
          ),
          user_name: user.sunetid, description: nil
        )
        expect(Sdr::Repository).to have_received(:accession)
          .with(cocina_object: updated_cocina_object, user_name: user.sunetid, context: {})
      end
    end

    context 'when saving a deposited item as a draft' do
      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'opens a version and saves the defaults without accessioning' do
        post "/objects/#{druid}/apo_defaults", params: { apo_defaults: form_params, commit: 'draft' }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('APO defaults applied.')
        expect(Sdr::VersionService).to have_received(:open)
        expect(Sdr::Repository).to have_received(:update)
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when depositing a Draft whose files have unsaved changes' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        content = create(:content, :mutable, druid:, lock: cocina_object.lock)
        create(:content_file_binary, content:, file_location: 'attached')
      end

      it 'renders the page with the error without depositing' do
        post "/objects/#{druid}/apo_defaults", params: { apo_defaults: form_params, commit: 'deposit' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_css('.alert-danger', text: 'Files have unsaved changes.')
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when depositing a collection' do
      let(:cocina_object) do
        build(:collection_with_metadata, id: druid, title: 'My collection', admin_policy_id: apo_druid, version: 2)
          .new(access: { view: 'world', copyright: 'Copyright me.' })
      end

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'saves the rights defaults, keeping the view access, and starts accessioning' do
        post "/objects/#{druid}/apo_defaults", params: { apo_defaults: { version_description: 'Reset rights' },
                                                         commit: 'deposit' }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:toast]).to eq('APO defaults applied and deposit started.')
        expect(Sdr::Repository).to have_received(:update).with(
          cocina_object: an_object_having_attributes(
            access: an_object_having_attributes(view: 'world', copyright: nil,
                                                useAndReproductionStatement: 'Ask the library.',
                                                license: 'https://creativecommons.org/licenses/by/4.0/legalcode')
          ),
          user_name: user.sunetid, description: nil
        )
        expect(Sdr::Repository).to have_received(:accession)
      end
    end

    context 'when the version description is blank' do
      let(:form_params) { { version_description: '' } }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'renders the page with the error without saving' do
        post "/objects/#{druid}/apo_defaults", params: { apo_defaults: form_params, commit: 'deposit' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_css('#apo_defaults_version_description_error')
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when other attributes of the item are submitted' do
      let(:form_params) { { version_description: 'Reset rights', title: 'Changed title', access_view: 'dark' } }

      before { create(:permission, :edit, workgroup: user.groups.first, target_druid: druid) }

      it 'does not change them' do
        post "/objects/#{druid}/apo_defaults", params: { apo_defaults: form_params, commit: 'deposit' }

        expect(response).to redirect_to(object_path(druid))
        expect(Sdr::Repository).to have_received(:update).with(
          cocina_object: an_object_having_attributes(
            access: an_object_having_attributes(view: 'stanford'),
            description: an_object_having_attributes(title: [an_object_having_attributes(value: 'My item')])
          ),
          user_name: user.sunetid, description: nil
        )
      end
    end

    context 'when the mutable Content is busy' do
      let(:version_service) { version_service_double(version: 2, version_description: 'Fixing the title') }

      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        create(:content, :mutable, druid:, lock: cocina_object.lock, staging_state: 'staging')
      end

      it 'redirects to the object page with a warning without saving' do
        post "/objects/#{druid}/apo_defaults", params: { apo_defaults: form_params, commit: 'deposit' }

        expect(response).to redirect_to(object_path(druid))
        expect(flash[:warning]).to eq('Files for this item are being staged, discovered, or structured. ' \
                                      'Try again when that has finished.')
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when saving to SDR fails' do
      before do
        create(:permission, :edit, workgroup: user.groups.first, target_druid: druid)
        allow(Sdr::VersionService).to receive(:open).and_raise(Sdr::VersionService::Error, 'Opening version failed')
      end

      it 'renders the page with an error without depositing' do
        post "/objects/#{druid}/apo_defaults", params: { apo_defaults: form_params, commit: 'deposit' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_css('.alert-danger', text: 'The APO defaults could not be applied. Try again, ' \
                                                                 'or contact SDR support if the problem continues.')
        expect(rendered_page).to have_field('Version description', with: 'Reset rights')
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when the user cannot edit the object' do
      it 'redirects to the root without saving' do
        post "/objects/#{druid}/apo_defaults", params: { apo_defaults: form_params, commit: 'deposit' }

        expect(response).to redirect_to(root_path)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end
  end
end
