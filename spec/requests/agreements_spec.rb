# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Agreements' do
  let(:user) { create(:user, groups: [workgroup]) }
  let(:workgroup) { 'sdr:test-workgroup' }

  before do
    create(:permission, :edit, workgroup:, target_druid: Settings.ur_apo_druid)
    sign_in(user)
  end

  describe 'new' do
    it 'renders the agreement form' do
      get '/agreements/new'

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      expect(page).to have_css('h1', text: 'Register an agreement')
      expect(page).to have_field('agreement[title]')
      expect(page).to have_field('agreement[source_id]')
      expect(page).to have_button('Register and add files')
      expect(page).to have_button('Register only')
      expect(page).to have_no_field('agreement[content_type]')
    end
  end

  describe 'create' do
    let(:registered_cocina_object) { build(:agreement_with_metadata, id: 'druid:xz987wv6543') }

    before do
      allow(Sdr::Repository).to receive_messages(register: registered_cocina_object, source_id_exists?: false)
    end

    context 'when registering only' do
      it 'registers a dark agreement governed by the ur APO' do
        # The content type, governing APO, and access cannot be set by the user.
        post '/agreements', params: { commit: 'draft',
                                      agreement: { title: 'My Agreement', source_id: 'sul:agreement-1',
                                                   apo_druid: 'druid:dd111dd1111', content_type: 'book',
                                                   access_view: 'world',
                                                   other_tags_attributes: { '0' => { tag: 'Some : Tag' } } } }

        expect(response).to redirect_to('/objects/druid:xz987wv6543')
        expect(flash[:toast]).to eq('Agreement registered.')
        expect(Sdr::Repository).to have_received(:register) do |args|
          request_cocina_object = args[:request_cocina_object]
          expect(request_cocina_object.type).to eq(Cocina::Models::ObjectType.agreement)
          expect(request_cocina_object.description.title.first.value).to eq('My Agreement')
          expect(request_cocina_object.administrative.hasAdminPolicy).to eq(Settings.ur_apo_druid)
          expect(request_cocina_object.access.to_h).to include(view: 'dark', download: 'none')
          expect(args[:tags]).to eq(['Some : Tag'])
        end
      end
    end

    context 'when registering and adding files' do
      it 'redirects to manage files' do
        post '/agreements', params: { commit: 'add_files',
                                      agreement: { title: 'My Agreement', source_id: 'sul:agreement-1' } }

        expect(response).to redirect_to('/contents/druid:xz987wv6543/edit')
      end
    end

    context 'when invalid' do
      it 'renders the form' do
        post '/agreements', params: { agreement: { source_id: 'sul:agreement-1' } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Sdr::Repository).not_to have_received(:register)
      end
    end
  end

  describe 'edit' do
    let(:druid) { 'druid:bc123df4567' }
    let(:cocina_object) do
      build(:agreement_with_metadata, id: druid, title: 'My agreement', source_id: 'sul:agreement-1')
    end
    let(:version_service) do
      version_service_double(open?: open, editable?: editable, version_description: 'Fixing the title')
    end
    let(:open) { true }
    let(:editable) { true }

    before do
      allow(Sdr::Repository).to receive(:find).and_return(cocina_object)
      allow(Sdr::VersionService).to receive(:new).and_return(version_service)
      allow(Sdr::PurgeService).to receive(:purgeable?).and_return(true)
    end

    it 'renders the details and deposit tabs with the current values' do
      get "/agreements/#{druid}/edit"

      expect(response).to have_http_status(:ok)
      page = Capybara.string(response.body)
      expect(page).to have_title('Edit agreement – My agreement | Argo B3', exact: true)
      expect(page).to have_css('h1', text: 'Edit agreement')
      expect(page).to have_css('h1 + p', text: 'My agreement')
      expect(page).to have_css('[role="tab"]', text: 'Agreement details')
      expect(page).to have_css('[role="tab"]', text: 'Deposit')
      expect(page).to have_no_css('[role="tab"]', text: 'Tags')
      expect(page).to have_field('Title', with: 'My agreement')
      expect(page).to have_field('Source ID', with: 'sul:agreement-1')
      expect(page).to have_field('agreement[lock]', type: :hidden, with: cocina_object.lock)
      expect(page).to have_no_field('agreement[content_type]')
      expect(Sdr::Repository).to have_received(:find).with(druid:)
    end

    it 'prefills the version description from the open version' do
      get "/agreements/#{druid}/edit"

      expect(Capybara.string(response.body)).to have_field('Version description', with: 'Fixing the title')
    end

    it 'renders the save, edit files, purge, and deposit buttons' do
      get "/agreements/#{druid}/edit"

      page = Capybara.string(response.body)
      expect(page).to have_button('Save as draft', count: 2)
      expect(page).to have_button('Save draft and edit files', count: 1)
      # The tab is also a button labeled "Deposit".
      expect(page).to have_button('Deposit', type: 'submit', count: 1)
      expect(page).to have_link('Purge', href: "/objects/#{druid}/purge", count: 2)
      expect(page).to have_link('Cancel', href: "/objects/#{druid}", count: 2)
    end

    context 'when the version is closed' do
      let(:open) { false }

      it 'renders an empty version description' do
        get "/agreements/#{druid}/edit"

        expect(Capybara.string(response.body).find_field('Version description').value).to be_blank
      end
    end

    context 'when depositing stopped with a process in error' do
      let(:version_service) do
        version_service_double(editable?: false, assembly_stopped_with_error?: true,
                               version_description: 'Fixing the title')
      end

      it 'renders the save as draft buttons without a deposit button' do
        get "/agreements/#{druid}/edit"

        expect(response).to have_http_status(:ok)
        page = Capybara.string(response.body)
        expect(page).to have_button('Save as draft', count: 2)
        expect(page).to have_no_button('Deposit', type: 'submit')
      end
    end

    context 'when the version is not editable' do
      let(:editable) { false }

      it 'redirects to the object page with an error' do
        get "/agreements/#{druid}/edit"

        expect(response).to redirect_to("/objects/#{druid}")
        expect(flash[:danger]).to eq('Agreement is not editable.')
      end
    end

    context 'when the user cannot edit the agreement' do
      let(:user) { create(:user, groups: ['sdr:other-workgroup']) }

      it 'denies access' do
        get "/agreements/#{druid}/edit"

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
      end
    end
  end

  describe 'update' do
    let(:druid) { 'druid:bc123df4567' }
    let(:cocina_object) do
      build(:agreement_with_metadata, id: druid, title: 'My agreement', source_id: 'sul:agreement-1')
    end
    let(:opened_cocina_object) { cocina_object.new(version: 2, lock: 'opened-lock') }
    let(:version_service) do
      version_service_double(open?: open, openable?: !open, closeable?: open, closed?: !open,
                             version_description: 'Changed the title')
    end
    let(:open) { false }
    let(:agreement_params) do
      { title: 'My new agreement', source_id: 'sul:agreement-2', version_description: 'Changed the title',
        lock: cocina_object.lock }
    end
    let(:commit) { AgreementsController::DRAFT_VALUE }

    before do
      allow(Sdr::Repository).to receive_messages(find: cocina_object, source_id_exists?: false, accession: nil)
      allow(Sdr::Repository).to receive(:update) { |cocina_object:, **| cocina_object }
      allow(Sdr::VersionService).to receive_messages(new: version_service, open: opened_cocina_object)
      allow(Sdr::PurgeService).to receive(:purgeable?).and_return(true)
    end

    it 'opens a version and saves the draft without depositing' do
      patch "/agreements/#{druid}", params: { agreement: agreement_params, commit: }

      expect(response).to redirect_to("/objects/#{druid}")
      expect(flash[:toast]).to eq('Agreement updated.')
      expect(Sdr::VersionService).to have_received(:open)
        .with(druid:, description: 'Changed the title', opening_user_name: user.sunetid)
      expect(Sdr::Repository).to have_received(:update) do |args|
        updated_cocina_object = args[:cocina_object]
        expect(updated_cocina_object.lock).to eq('opened-lock')
        expect(updated_cocina_object.description.title.first.value).to eq('My new agreement')
        expect(updated_cocina_object.identification.sourceId).to eq('sul:agreement-2')
        expect(args[:user_name]).to eq(user.sunetid)
      end
      expect(Sdr::Repository).not_to have_received(:accession)
    end

    it 'does not change the content type, governing APO, or access' do
      patch "/agreements/#{druid}", params: {
        commit:, agreement: agreement_params.merge(content_type: Cocina::Models::ObjectType.book,
                                                   apo_druid: 'druid:cd234fg5678', access_view: 'world',
                                                   access_download: 'world')
      }

      expect(Sdr::Repository).to have_received(:update) do |args|
        updated_cocina_object = args[:cocina_object]
        expect(updated_cocina_object.type).to eq(Cocina::Models::ObjectType.agreement)
        expect(updated_cocina_object.administrative.hasAdminPolicy).to eq('druid:hv992ry2431')
        expect(updated_cocina_object.access).to have_attributes(view: 'dark', download: 'none')
      end
    end

    context 'when saving as a draft and editing files' do
      let(:commit) { AgreementsController::DRAFT_TO_ADD_FILES_VALUE }

      it 'saves and redirects to manage files' do
        patch "/agreements/#{druid}", params: { agreement: agreement_params, commit: }

        expect(response).to redirect_to("/contents/#{druid}/edit")
        expect(Sdr::Repository).to have_received(:update)
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when depositing' do
      let(:commit) { AgreementsController::DEPOSIT_VALUE }

      it 'saves and then starts accessioning' do
        patch "/agreements/#{druid}", params: { agreement: agreement_params, commit: }

        expect(response).to redirect_to("/objects/#{druid}")
        expect(flash[:toast]).to eq('Agreement updated and deposit started.')
        expect(Sdr::Repository).to have_received(:update)
        expect(Sdr::Repository).to have_received(:accession)
          .with(cocina_object: having_attributes(lock: 'opened-lock'), user_name: user.sunetid, context: {})
      end
    end

    context 'when depositing a structure that is invalid for an agreement' do
      let(:commit) { AgreementsController::DEPOSIT_VALUE }

      before do
        content = create(:content, druid:, lock: cocina_object.lock)
        # An agreement's files must not be published.
        create(:content_file, content_file_set: create(:content_file_set, content:, file_set_type: 'file'),
                              publish: true)
      end

      it 'renders the edit page with the error without depositing' do
        patch "/agreements/#{druid}", params: { agreement: agreement_params, commit: }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Capybara.string(response.body))
          .to have_css('.invalid-feedback', text: 'The files are not valid for the content type.')
        expect(Sdr::Repository).not_to have_received(:accession)
      end
    end

    context 'when the version description is missing' do
      it 'renders the edit page with the error and the saved title without saving' do
        patch "/agreements/#{druid}", params: { agreement: agreement_params.merge(version_description: ''), commit: }

        expect(response).to have_http_status(:unprocessable_content)
        page = Capybara.string(response.body)
        expect(page).to have_css('h1', text: 'Edit agreement')
        expect(page).to have_css('h1 + p', text: 'My agreement')
        expect(page).to have_css('.invalid-feedback', text: "can't be blank")
        expect(page).to have_field('Title', with: 'My new agreement')
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the agreement was changed since the form was loaded' do
      it 'redirects to the edit page with an error without saving' do
        patch "/agreements/#{druid}", params: { agreement: agreement_params.merge(lock: 'stale-lock'), commit: }

        expect(response).to redirect_to("/agreements/#{druid}/edit")
        expect(flash[:danger]).to eq('This agreement was changed since you opened it. ' \
                                     'Review the current values and make your changes again.')
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the mutable content is staging' do
      before { create(:content, :mutable, druid:, lock: cocina_object.lock, staging_state: 'staging') }

      it 'redirects to the edit page with an error without saving' do
        patch "/agreements/#{druid}", params: { agreement: agreement_params, commit: }

        expect(response).to redirect_to("/agreements/#{druid}/edit")
        expect(flash[:danger]).to eq('Files for this agreement are being staged or discovered. ' \
                                     'Try again when that has finished.')
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when depositing stopped with a process in error' do
      let(:version_service) do
        version_service_double(closeable?: false, assembly_stopped_with_error?: true,
                               version_description: 'Changed the title')
      end

      it 'saves the draft' do
        patch "/agreements/#{druid}", params: { agreement: agreement_params, commit: }

        expect(response).to redirect_to("/objects/#{druid}")
        expect(flash[:toast]).to eq('Agreement updated.')
        expect(Sdr::Repository).to have_received(:update)
      end

      context 'when depositing' do
        let(:commit) { AgreementsController::DEPOSIT_VALUE }

        it 'redirects to the object page with a warning without saving' do
          patch "/agreements/#{druid}", params: { agreement: agreement_params, commit: }

          expect(response).to redirect_to("/objects/#{druid}")
          expect(flash[:warning]).to eq("This agreement can't be deposited until the process in error is retried.")
          expect(Sdr::Repository).not_to have_received(:update)
          expect(Sdr::Repository).not_to have_received(:accession)
        end
      end
    end

    context 'when the version is not editable' do
      let(:version_service) { version_service_double(open?: false, openable?: false, closeable?: false) }

      it 'redirects to the object page with an error without saving' do
        patch "/agreements/#{druid}", params: { agreement: agreement_params, commit: }

        expect(response).to redirect_to("/objects/#{druid}")
        expect(flash[:danger]).to eq('Agreement is not editable.')
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end

    context 'when the user cannot edit the agreement' do
      let(:user) { create(:user, groups: ['sdr:other-workgroup']) }

      it 'denies access' do
        patch "/agreements/#{druid}", params: { agreement: agreement_params, commit: }

        expect(response).to redirect_to(root_path)
        expect(Sdr::Repository).not_to have_received(:update)
      end
    end
  end

  context 'when the user does not have edit permission for the ur APO' do
    let(:user) { create(:user, groups: ['sdr:other-workgroup']) }

    before do
      allow(Sdr::Repository).to receive(:register)
    end

    it 'denies access to the new agreement form' do
      get '/agreements/new'

      expect(response).to redirect_to(root_path)
      expect(flash[:danger]).to eq('You are not authorized to perform the requested action.')
    end

    it 'denies creating an agreement' do
      post '/agreements', params: { agreement: { title: 'My Agreement', source_id: 'sul:agreement-1' } }

      expect(response).to redirect_to(root_path)
      expect(Sdr::Repository).not_to have_received(:register)
    end
  end
end
