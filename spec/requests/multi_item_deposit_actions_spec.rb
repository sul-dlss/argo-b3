# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Multi-item deposit actions' do
  let(:workgroup) { 'sdr:test-workgroup' }
  let(:user) { create(:user, groups: [workgroup]) }
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    sign_in(user)
  end

  describe 'index' do
    let!(:user_multi_item_deposit_action) { create(:multi_item_deposit_action, user:, updated_at: 2.days.ago) }
    let!(:recent_user_multi_item_deposit_action) do
      create(:multi_item_deposit_action, user:, step: :submitted, initiating_deposit_completed_at: 1.day.ago)
    end
    let(:other_user) { create(:user) }
    let!(:other_user_multi_item_deposit_action) { create(:multi_item_deposit_action, user: other_user) }

    it 'lists the Multi-Item Deposits of the user, most recently updated first' do
      get multi_item_deposit_actions_path

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_css('h1', text: 'Multi-item deposits')
      expect(rendered_page.all('#multi-item-deposits-history-table tbody tr').pluck(:id))
        .to eq(["row_multi_item_deposit_action_#{recent_user_multi_item_deposit_action.id}",
                "row_multi_item_deposit_action_#{user_multi_item_deposit_action.id}"])
    end

    it 'lists only the Multi-Item Deposits with the selected statuses' do
      get multi_item_deposit_actions_path(multi_item_deposit_filter: { statuses: ['', 'submitted'] })

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_css("tr#row_multi_item_deposit_action_#{recent_user_multi_item_deposit_action.id}")
      expect(rendered_page).to have_no_css("tr#row_multi_item_deposit_action_#{user_multi_item_deposit_action.id}")
    end

    it 'lists only the Multi-Item Deposits submitted within the range' do
      get multi_item_deposit_actions_path(multi_item_deposit_filter: { submitted_date: 'last_7_days' })

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_css("tr#row_multi_item_deposit_action_#{recent_user_multi_item_deposit_action.id}")
      expect(rendered_page).to have_no_css("tr#row_multi_item_deposit_action_#{user_multi_item_deposit_action.id}")
    end

    it 'ignores the selected users' do
      get multi_item_deposit_actions_path(multi_item_deposit_filter: { user_ids: ['', other_user.id.to_s] })

      expect(response).to have_http_status(:ok)
      expect(rendered_page).to have_css("tr#row_multi_item_deposit_action_#{user_multi_item_deposit_action.id}")
      expect(rendered_page)
        .to have_no_css("tr#row_multi_item_deposit_action_#{other_user_multi_item_deposit_action.id}")
    end

    context 'when there are more Multi-Item Deposits than fit on one page' do
      before { create_list(:multi_item_deposit_action, MultiItemDepositActionsController::PER_PAGE, user:) }

      it 'paginates' do
        get multi_item_deposit_actions_path(page: 2)

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('#multi-item-deposits-history-table tbody tr', count: 2)
      end
    end

    context 'when there are no Multi-Item Deposits' do
      let(:user_multi_item_deposit_action) { nil }
      let(:recent_user_multi_item_deposit_action) { nil }

      it 'renders the empty message' do
        get multi_item_deposit_actions_path

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('p', text: 'No multi-item deposits yet')
      end
    end

    context 'when an admin' do
      let(:user) { create(:user, :admin) }

      it 'lists only the Multi-Item Deposits of the admin by default' do
        get multi_item_deposit_actions_path

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css("tr#row_multi_item_deposit_action_#{user_multi_item_deposit_action.id}")
        expect(rendered_page)
          .to have_no_css("tr#row_multi_item_deposit_action_#{other_user_multi_item_deposit_action.id}")
      end

      it 'lists the Multi-Item Deposits of the selected users' do
        get multi_item_deposit_actions_path(multi_item_deposit_filter: { user_ids: ['', other_user.id.to_s] })

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_no_css("tr#row_multi_item_deposit_action_#{user_multi_item_deposit_action.id}")
        expect(rendered_page).to have_css("tr#row_multi_item_deposit_action_#{other_user_multi_item_deposit_action.id}")
      end
    end
  end

  describe 'create' do
    context 'when the user belongs to a workgroup with edit permission' do
      before do
        create(:permission, :edit, workgroup:, target_druid: 'druid:bc123df4567')
      end

      it 'creates a multi-item deposit action and redirects to the edit page' do
        expect { post multi_item_deposit_actions_path }.to change(MultiItemDepositAction, :count).by(1)

        multi_item_deposit_action = MultiItemDepositAction.last
        expect(multi_item_deposit_action.user).to eq(user)
        expect(multi_item_deposit_action).to be_discovery_step
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when the user is an admin' do
      let(:user) { create(:user, :admin) }

      it 'creates a multi-item deposit action' do
        expect { post multi_item_deposit_actions_path }.to change(MultiItemDepositAction, :count).by(1)
      end
    end

    context 'when the user does not belong to a workgroup with edit permission' do
      it 'denies access' do
        expect { post multi_item_deposit_actions_path }.not_to change(MultiItemDepositAction, :count)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'show' do
    let(:multi_item_deposit_action) do
      create(:multi_item_deposit_action, user: owner, step: 'submitted', description: 'My deposit')
    end

    context 'when the multi-item deposit action belongs to the user' do
      let(:owner) { user }
      let(:closed_status) do
        Dor::Services::Client::ObjectVersion::VersionStatus.new(open: false, openable: true, assembling: false,
                                                                accessioning: false, closeable: false)
      end
      let(:open_status) do
        Dor::Services::Client::ObjectVersion::VersionStatus.new(open: true, openable: false, assembling: false,
                                                                accessioning: false, closeable: true)
      end

      before do
        create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:cd234fg5678', manifest_line_number: 3)
        create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567', manifest_line_number: 2)
        allow(Searchers::ItemByDruid).to receive(:call).and_return(
          [SearchResults::Item.new(solr_doc: build(:solr_item, druid: 'druid:cd234fg5678')),
           SearchResults::Item.new(solr_doc: build(:solr_item, druid: 'druid:bc123df4567'))]
        )
        allow(Sdr::VersionService).to receive(:statuses)
          .and_return({ 'druid:bc123df4567' => closed_status, 'druid:cd234fg5678' => open_status })
      end

      it 'renders the deposit status of each Item Deposit in manifest order' do
        get multi_item_deposit_action_path(multi_item_deposit_action)

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('h1', text: 'Multi-item deposit')
        expect(rendered_page).to have_css('p', text: "Multi-item deposit #{multi_item_deposit_action.id}: My deposit")
        expect(rendered_page).to have_css('div[data-controller="scheduled-refresh"]')

        rows = rendered_page.all('table[aria-label="Deposit status"] tbody tr')
        expect(rows.map { |row| row.all('td').map { |cell| cell.text.strip } })
          .to eq([%w[bc123df4567 Deposited], ['cd234fg5678', 'Draft, not deposited']])
        expect(rows[0]).to have_link('bc123df4567', href: '/objects/druid:bc123df4567')

        expect(Sdr::VersionService).to have_received(:statuses).with(druids: ['druid:bc123df4567', 'druid:cd234fg5678'])
      end

      context 'when the deposit is being initiated' do
        let(:multi_item_deposit_action) do
          create(:multi_item_deposit_action, user: owner, step: 'submitted',
                                             initiating_deposit_state: 'initiating_depositing')
        end

        it 'renders the Item Deposits as initiating' do
          get multi_item_deposit_action_path(multi_item_deposit_action)

          rows = rendered_page.all('table[aria-label="Deposit status"] tbody tr')
          expect(rows.map { |row| row.all('td').map { |cell| cell.text.strip } })
            .to eq([['bc123df4567', 'Initiating deposit...'], ['cd234fg5678', 'Initiating deposit...']])
        end
      end
    end

    context 'when the multi-item deposit action has not been submitted' do
      let(:owner) { user }
      let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, step: 'deposit') }

      it 'redirects to the edit page' do
        get multi_item_deposit_action_path(multi_item_deposit_action)

        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when the multi-item deposit action belongs to another user' do
      let(:owner) { create(:user) }

      it 'denies access' do
        get multi_item_deposit_action_path(multi_item_deposit_action)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'edit' do
    let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, description: 'My deposit') }

    context 'when the multi-item deposit action belongs to the user' do
      let(:owner) { user }

      it 'renders the edit page' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('h1', text: 'Multi-item deposit')
        expect(rendered_page).to have_css('p', text: "Multi-item deposit #{multi_item_deposit_action.id}: My deposit")
        expect(rendered_page).to have_field('Describe this deposit', with: 'My deposit')
        expect(rendered_page).to have_button('Discover files and check manifest', class: 'btn-primary')
        expect(rendered_page).to have_link('Cancel', href: root_path)
        expect(rendered_page).to have_field('Upload from a computer', type: 'radio', checked: true)
        expect(rendered_page).to have_field('Include with your files below', type: 'radio')
        expect(rendered_page).to have_field('Upload manifest file', type: 'file')
        expect(rendered_page).to have_field('Use files from Globus', type: 'radio', disabled: false)
        expect(rendered_page).to have_css('turbo-frame[data-radio-src=' \
                                          "'#{new_multi_item_deposit_action_globus_path(multi_item_deposit_action)}']")
        expect(rendered_page).to have_css("form#create-globus-link-form[action='" \
                                          "#{multi_item_deposit_action_globus_path(multi_item_deposit_action)}']")
        expect(rendered_page).to have_field('Use files from mount', type: 'radio', checked: true)
        expect(rendered_page).to have_field('Mount path')
        expect(rendered_page).to have_no_css('table[aria-label="Error details"]')
        expect(rendered_page).to have_button('Next', disabled: true)
      end
    end

    context 'when discovery has completed and an Item Deposit has a discovery error' do
      let(:owner) { user }

      before do
        multi_item_deposit_action.update!(discovery_completed_at: Time.current)
        create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567',
                                     discovery_errors: ['Object not found'])
      end

      it 'renders the results of checking the manifest' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(rendered_page).to have_css('h2', text: 'Results of checking manifest')
        expect(rendered_page).to have_no_css('.alert-success')
        expect(rendered_page).to have_css('.alert-danger', text: 'We found errors with the manifest.')
        expect(rendered_page).to have_css(
          '.alert-danger',
          text: 'Please fix your manifest and / or files and click "Discover files and check manifest" again.'
        )

        table = rendered_page.find('table[aria-label="Error details"]')
        expect(table).to have_css('td', text: 'bc123df4567')
        expect(table).to have_css('td span.text-danger', text: 'Object not found')
        expect(rendered_page).to have_button('Next', disabled: true)
      end
    end

    context 'when discovery has completed and Item Deposits have only discovery warnings' do
      let(:owner) { user }

      before do
        multi_item_deposit_action.update!(discovery_completed_at: Time.current)
        create(:item_deposit_action, multi_item_deposit_action:, discovery_warnings: ['Version cannot be opened'])
      end

      it 'renders the warnings without the errors alert' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(rendered_page).to have_css('table[aria-label="Error details"]', text: 'Version cannot be opened')
        expect(rendered_page).to have_no_css('.alert-danger')
        expect(rendered_page).to have_css('.alert-success', text: 'No errors with manifest')
        expect(rendered_page).to have_css('.alert-success', text: 'Click "Next" to proceed.')
        expect(rendered_page).to have_button('Next', disabled: false)
        expect(rendered_page).to have_button('Discover files and check manifest', class: 'btn-outline-primary')
      end
    end

    context 'when discovery has completed with the manifest included with the files' do
      let(:owner) { user }

      before do
        multi_item_deposit_action.update!(discovery_completed_at: Time.current, manifest_source: 'mount',
                                          manifest_csv: "druid,folder_name\ndruid:bc123df4567,folder1\n")
      end

      it 'selects the saved manifest source' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(rendered_page).to have_field('Include with your files below', type: 'radio', checked: true)
        expect(rendered_page).to have_no_text('A manifest has been uploaded.')
      end
    end

    context 'when discovery has completed with an uploaded manifest' do
      let(:owner) { user }

      before do
        multi_item_deposit_action.update!(discovery_completed_at: Time.current, manifest_source: 'upload',
                                          manifest_csv: "druid,folder_name\ndruid:bc123df4567,folder1\n")
      end

      it 'notes the saved manifest without carrying it in the form' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(rendered_page).to have_field('Upload from a computer', type: 'radio', checked: true)
        expect(rendered_page).to have_text('A manifest has been uploaded.')
        expect(rendered_page).to have_no_field('multi_item_deposit_discovery[manifest_csv]', type: :hidden)
      end
    end

    context 'when the multi-item deposit action is in the structure step' do
      let(:owner) { user }
      let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, step: 'structure') }

      it 'renders the structure page' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('h1', text: 'Multi-item deposit')
        expect(rendered_page).to have_css('p', exact_text: "Multi-item deposit #{multi_item_deposit_action.id}")
        expect(rendered_page).to have_no_field('Mount path')
        expect(rendered_page).to have_link(
          'Download structural metadata template CSV',
          href: structural_metadata_csv_template_multi_item_deposit_action_path(multi_item_deposit_action)
        )
      end

      it 'renders the OCR inputs when an Item Deposit can be OCRed' do
        create(:item_deposit_action, multi_item_deposit_action:, content_type: 'image')

        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(rendered_page).to have_css('legend', text: 'Run OCR?')
      end

      it 'does not render the OCR inputs when no Item Deposit can be OCRed' do
        create(:item_deposit_action, multi_item_deposit_action:, content_type: 'map')

        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(rendered_page).to have_no_css('legend', text: 'Run OCR?')
      end

      it 'renders the summary of the Item Deposits once structuring has completed' do
        multi_item_deposit_action.update!(structuring_completed_at: Time.current)
        create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567')

        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(rendered_page).to have_css('table[aria-label="Summary"] td', text: 'bc123df4567')
      end

      it 'renders Previous and a disabled Next until structuring succeeds' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(rendered_page).to have_button('Previous')
        expect(rendered_page).to have_button('Next', disabled: true)
        expect(rendered_page).to have_button('Check files', class: 'btn-primary')
      end

      it 'renders an enabled Next and an outlined Check files once structuring succeeds' do
        multi_item_deposit_action.update!(structuring_completed_at: Time.current)

        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(rendered_page).to have_button('Next', disabled: false)
        expect(rendered_page).to have_button('Check files', class: 'btn-outline-primary')
      end

      it 'renders the structural metadata CSV choice without the mount option' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(rendered_page).to have_field('Yes, upload a structural metadata CSV', type: 'radio', checked: false)
        expect(rendered_page).to have_field('Upload structural metadata CSV', type: 'file')
        expect(rendered_page).to have_no_field('Yes, use structural metadata CSV found in file location')
        expect(rendered_page).to have_field('No', type: 'radio', checked: true)
        expect(rendered_page).to have_field('Default by file type', type: 'radio', checked: true)
        expect(rendered_page).to have_field('Publish and preserve all files', type: 'radio', checked: false)
      end

      context 'when a structural metadata CSV is on the mount' do
        let(:mount_directory) { Dir.mktmpdir(nil, Rails.root.join('tmp')) }
        let(:multi_item_deposit_action) do
          create(:multi_item_deposit_action, user: owner, step: 'structure', mount_path: mount_directory)
        end

        before { File.write(File.join(mount_directory, 'structural_metadata.csv'), 'druid') }

        after { FileUtils.rm_rf(mount_directory) }

        it 'renders the mount option selected' do
          get edit_multi_item_deposit_action_path(multi_item_deposit_action)

          expect(rendered_page).to have_field('Yes, use structural metadata CSV found in file location',
                                              type: 'radio', checked: true)
        end
      end

      context 'when an Item Deposit is media' do
        before { create(:item_deposit_action, multi_item_deposit_action:, content_type: 'media') }

        it 'requires a structural metadata CSV' do
          get edit_multi_item_deposit_action_path(multi_item_deposit_action)

          expect(rendered_page).to have_field('Yes, upload a structural metadata CSV', type: 'radio', checked: true)
          expect(rendered_page).to have_no_field('No', type: 'radio')
          expect(rendered_page).to have_no_field('Default by file type')
        end
      end
    end

    context 'when the multi-item deposit action is in the deposit step' do
      let(:owner) { user }
      let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, step: 'deposit') }

      context 'when every Item Deposit is an initial version' do
        before do
          create(:item_deposit_action, multi_item_deposit_action:, initial_version: true)
        end

        it 'renders the deposit page with the version description set' do
          get edit_multi_item_deposit_action_path(multi_item_deposit_action)

          expect(response).to have_http_status(:ok)
          expect(rendered_page).to have_css('p', exact_text: "Multi-item deposit #{multi_item_deposit_action.id}")
          expect(rendered_page).to have_field('Version description', with: 'Initial version', disabled: true)
          expect(rendered_page).to have_text('Version description is automatically set for initial deposits.')
          expect(rendered_page).to have_link('Cancel', href: root_path)
          expect(rendered_page).to have_button('Previous')
          expect(rendered_page).to have_button('Check version status and deposit')
        end
      end

      context 'when checking version status found deposit errors' do
        let(:multi_item_deposit_action) do
          create(:multi_item_deposit_action, user: owner, step: 'deposit',
                                             initiating_deposit_completed_at: Time.current)
        end

        before do
          create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567',
                                       deposit_errors: ['Version cannot be opened'])
        end

        it 'renders the error details' do
          get edit_multi_item_deposit_action_path(multi_item_deposit_action)

          expect(rendered_page).to have_css('h2', text: 'Results of checking version status')
          table = rendered_page.find('table[aria-label="Error details"]')
          expect(table).to have_css('td', text: 'bc123df4567')
          expect(table).to have_css('span.text-danger', text: 'Version cannot be opened')
        end
      end

      context 'when an Item Deposit is not an initial version' do
        before do
          create(:item_deposit_action, multi_item_deposit_action:, initial_version: true)
          create(:item_deposit_action, multi_item_deposit_action:, initial_version: false)
        end

        it 'renders the deposit page with the version description to enter' do
          get edit_multi_item_deposit_action_path(multi_item_deposit_action)

          expect(response).to have_http_status(:ok)
          expect(rendered_page).to have_field('Version description', disabled: false)
          expect(rendered_page).to have_no_text('Version description is automatically set for initial deposits.')
        end
      end
    end

    context 'when discovery is in progress' do
      let(:owner) { user }
      let(:multi_item_deposit_action) do
        create(:multi_item_deposit_action, user: owner, description: 'My deposit', discovery_state: 'discovering')
      end

      it 'renders the wait page' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(response).to have_http_status(:ok)
        expect(rendered_page)
          .to have_text("Processing Multi-item deposit #{multi_item_deposit_action.id}: My deposit...")
        expect(rendered_page).to have_no_field('Describe this deposit')
      end
    end

    context 'when the multi-item deposit action has been submitted' do
      let(:owner) { user }
      let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, step: 'submitted') }

      it 'redirects to the show page' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(response).to redirect_to(multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when the multi-item deposit action belongs to another user' do
      let(:owner) { create(:user) }

      it 'denies access' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'update' do
    let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, description: 'My deposit') }
    let(:mount_directory) { Dir.mktmpdir(nil, Rails.root.join('tmp')) }
    let(:mount_params) { { file_location: 'mount', mount_path: mount_directory } }
    let(:params) do
      { multi_item_deposit_discovery: { description: '  My updated deposit  ',
                                        manifest_source: 'mount', **mount_params } }
    end

    # The test database has no queue tables, so a verifying double (which loads the schema) cannot be used.
    let(:batch_class) { double('SolidQueue::Batch') } # rubocop:disable RSpec/VerifiedDoubles

    before do
      File.write(File.join(mount_directory, 'manifest.csv'), "druid,folder_name\nbc123df4567,folder1\n")
      stub_const('SolidQueue::Batch', batch_class)
      allow(batch_class).to receive(:enqueue).and_yield
    end

    after do
      FileUtils.rm_rf(mount_directory)
    end

    context 'when the multi-item deposit action belongs to the user' do
      let(:owner) { user }

      it 'updates the deposit, starts discovery, and redirects to the edit page' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        multi_item_deposit_action.reload
        expect(multi_item_deposit_action).to be_discovering
        item_deposit_action = multi_item_deposit_action.item_deposit_actions.sole
        expect(item_deposit_action).to have_attributes(druid: 'druid:bc123df4567', path: 'folder1')
        expect(MultiItemDeposit::DiscoverFilesJob).to have_been_enqueued
          .with(item_deposit_action:, effective_groups: [workgroup])
        expect(multi_item_deposit_action.description).to eq('My updated deposit')
        expect(multi_item_deposit_action).to be_file_location_mount
        expect(multi_item_deposit_action.mount_path).to eq(mount_directory)
        expect(multi_item_deposit_action).to be_manifest_source_mount
        expect(multi_item_deposit_action.manifest_csv).to eq("druid,folder_name\ndruid:bc123df4567,folder1\n")
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when the manifest is uploaded' do
      let(:owner) { user }
      let(:params) do
        { multi_item_deposit_discovery: { manifest_source: 'upload', manifest_file:, **mount_params } }
      end
      let(:manifest_file) { Rack::Test::UploadedFile.new(csv_tempfile.path, 'text/csv') }
      let(:csv_tempfile) do
        Tempfile.new(['manifest', '.csv']).tap do |file|
          file.write("druid,folder_name\ncd234fg5678,folder2\n") && file.flush
        end
      end

      it 'saves the normalized manifest and creates the Item Deposits from it' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        multi_item_deposit_action.reload
        expect(multi_item_deposit_action.item_deposit_actions.pluck(:druid)).to eq(['druid:cd234fg5678'])
        expect(multi_item_deposit_action).to be_manifest_source_upload
        expect(multi_item_deposit_action.manifest_csv).to eq("druid,folder_name\ndruid:cd234fg5678,folder2\n")
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end

      context 'when the mount path is not valid' do
        let(:mount_params) { { file_location: 'mount', mount_path: File.join(mount_directory, 'missing') } }

        it 'renders the discovery page with the manifest retained' do
          patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

          expect(response).to have_http_status(:unprocessable_content)
          expect(rendered_page).to have_text('A manifest has been uploaded.')
          expect(rendered_page.find_field('multi_item_deposit_discovery[manifest_csv]', type: :hidden).value)
            .to eq("druid,folder_name\ndruid:cd234fg5678,folder2\n")
        end
      end
    end

    context 'when the manifest was uploaded with an earlier submit' do
      let(:owner) { user }
      let(:params) do
        { multi_item_deposit_discovery: { manifest_source: 'upload',
                                          manifest_csv: "druid,folder_name\r\ndruid:cd234fg5678,folder2\r\n",
                                          **mount_params } }
      end

      it 'creates the Item Deposits from the earlier manifest' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(multi_item_deposit_action.reload.item_deposit_actions.pluck(:druid, :path))
          .to eq([['druid:cd234fg5678', 'folder2']])
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when rediscovering with the saved uploaded manifest' do
      let(:owner) { user }
      let(:multi_item_deposit_action) do
        create(:multi_item_deposit_action, user: owner, manifest_source: 'upload',
                                           manifest_csv: "druid,folder_name\ndruid:cd234fg5678,folder2\n")
      end
      let(:params) { { multi_item_deposit_discovery: { manifest_source: 'upload', **mount_params } } }

      it 'creates the Item Deposits from the saved manifest' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(multi_item_deposit_action.reload.item_deposit_actions.pluck(:druid, :path))
          .to eq([['druid:cd234fg5678', 'folder2']])
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when switching to upload without a file after including the manifest with the files' do
      let(:owner) { user }
      let(:multi_item_deposit_action) do
        create(:multi_item_deposit_action, user: owner, manifest_source: 'mount',
                                           manifest_csv: "druid,folder_name\ndruid:cd234fg5678,folder2\n")
      end
      let(:params) { { multi_item_deposit_discovery: { manifest_source: 'upload', **mount_params } } }

      it 'does not use the saved manifest' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_text("can't be blank")
      end
    end

    context 'when the manifest is uploaded without a file' do
      let(:owner) { user }
      let(:params) { { multi_item_deposit_discovery: { manifest_source: 'upload', **mount_params } } }

      it 'does not save and renders the discovery page' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_text("can't be blank")
        expect(multi_item_deposit_action.reload.mount_path).to be_nil
      end
    end

    context 'when the manifest included with the files is not valid' do
      let(:owner) { user }

      before do
        File.write(File.join(mount_directory, 'manifest.csv'), "druid,folder_name\nbc123df4567,\n")
      end

      it 'does not save and renders the discovery page' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_text('Blank folder_name in rows: 2.')
        expect(multi_item_deposit_action.reload.mount_path).to be_nil
        expect(multi_item_deposit_action.item_deposit_actions).to be_empty
        expect(batch_class).not_to have_received(:enqueue)
      end
    end

    context 'when the mount path is not valid' do
      let(:owner) { user }
      let(:mount_params) { { file_location: 'mount', mount_path: File.join(mount_directory, 'missing') } }

      it 'does not save and renders the discovery page' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_text('does not exist')
        expect(multi_item_deposit_action.reload.mount_path).to be_nil
      end
    end

    context 'when the files are on Globus' do
      let(:owner) { user }
      let(:multi_item_deposit_action) do
        create(:multi_item_deposit_action, user: owner, globus_path: '/uploads/jdoe/2026-10-28-14-03-22-417')
      end
      let(:globus_local_path) { "#{Settings.globus.directory}/uploads/jdoe/2026-10-28-14-03-22-417" }
      let(:mount_params) { { file_location: 'globus' } }

      before do
        FileUtils.mkdir_p(globus_local_path)
        File.write(File.join(globus_local_path, 'manifest.csv'), "druid,folder_name\ncd234fg5678,folder2\n")
      end

      after do
        FileUtils.rm_rf(Settings.globus.directory)
      end

      it 'starts discovery from the Globus directory' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        multi_item_deposit_action.reload
        expect(multi_item_deposit_action).to be_discovering
        expect(multi_item_deposit_action).to be_file_location_globus
        expect(multi_item_deposit_action.mount_path).to be_nil
        expect(multi_item_deposit_action.files_path).to eq(globus_local_path)
        expect(multi_item_deposit_action.item_deposit_actions.pluck(:druid, :path))
          .to eq([['druid:cd234fg5678', 'folder2']])
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end

      context 'when a Globus path is submitted' do
        let(:mount_params) { { file_location: 'globus', globus_path: '/uploads/other' } }

        it 'uses the saved Globus directory' do
          patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

          expect(multi_item_deposit_action.reload.globus_path).to eq('/uploads/jdoe/2026-10-28-14-03-22-417')
          expect(multi_item_deposit_action.item_deposit_actions.pluck(:druid, :path))
            .to eq([['druid:cd234fg5678', 'folder2']])
        end
      end

      context 'when the Globus link has not been created' do
        let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner) }

        it 'does not save and renders the discovery page' do
          patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

          expect(response).to have_http_status(:unprocessable_content)
          expect(rendered_page).to have_text('Create a Globus link before discovering files')
          expect(multi_item_deposit_action.reload.item_deposit_actions).to be_empty
        end
      end
    end

    context 'when discovery is in progress' do
      let(:owner) { user }
      let(:multi_item_deposit_action) do
        create(:multi_item_deposit_action, user: owner, description: 'My deposit', discovery_state: 'discovering')
      end

      it 'does not restart discovery and redirects to the edit page' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
        expect(multi_item_deposit_action.reload.description).to eq('My deposit')
        expect(multi_item_deposit_action.item_deposit_actions).to be_empty
        expect(batch_class).not_to have_received(:enqueue)
      end
    end

    context 'when proceeding after discovery succeeded' do
      let(:owner) { user }

      before do
        multi_item_deposit_action.update!(discovery_completed_at: Time.current)
        create(:item_deposit_action, multi_item_deposit_action:, discovery_warnings: ['Version cannot be opened'])
      end

      it 'moves to the structure step without restarting discovery' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params: { commit: 'next' })

        expect(multi_item_deposit_action.reload).to be_structure_step
        expect(multi_item_deposit_action.item_deposit_actions.count).to eq(1)
        expect(batch_class).not_to have_received(:enqueue)
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when proceeding after discovery found errors' do
      let(:owner) { user }

      before do
        multi_item_deposit_action.update!(discovery_completed_at: Time.current)
        create(:item_deposit_action, multi_item_deposit_action:, discovery_errors: ['Object not found'])
      end

      it 'stays in the discovery step' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params: { commit: 'next' })

        expect(multi_item_deposit_action.reload).to be_discovery_step
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when building the structure' do
      let(:owner) { user }
      let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, step: 'structure') }
      let!(:item_deposit_action) { create(:item_deposit_action, multi_item_deposit_action:) }
      let(:params) do
        { multi_item_deposit_structure: { perform_ocr: 'true', ocr_languages: ['', 'English'] } }
      end

      it 'saves the OCR settings, starts structuring, and redirects to the edit page' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(multi_item_deposit_action.reload).to be_structuring
        expect(multi_item_deposit_action).to have_attributes(perform_ocr: true, ocr_languages: ['English'])
        expect(MultiItemDeposit::StructureJob).to have_been_enqueued.with(item_deposit_action:)
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when building the structure from an uploaded structural metadata CSV' do
      let(:owner) { user }
      let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, step: 'structure') }
      let(:csv_header) { 'druid,sequence,filename,publish,preserve,rights_view,rights_download,rights_location' }
      let(:csv_tempfile) do
        Tempfile.new(['structural', '.csv']).tap do |file|
          file.write("#{csv_header}\nbc123df4567,1,file1.tif,yes,yes,world,world,\n") && file.flush
        end
      end
      let(:params) do
        { multi_item_deposit_structure: {
          structural_metadata_csv_choice: 'upload',
          structural_metadata_csv_file: Rack::Test::UploadedFile.new(csv_tempfile.path, 'text/csv')
        } }
      end

      it 'saves the CSV and starts structuring' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(multi_item_deposit_action.reload).to be_structuring
        expect(multi_item_deposit_action).to have_attributes(
          structural_metadata_csv: "#{csv_header}\ndruid:bc123df4567,1,file1.tif,yes,yes,world,world,\n",
          structural_metadata_csv_source: 'upload', publish_preserve_all: false
        )
      end

      context 'when the form has other errors' do
        let(:params) do
          { multi_item_deposit_structure: {
            structural_metadata_csv_choice: 'upload', perform_ocr: 'true', ocr_languages: [''],
            structural_metadata_csv_file: Rack::Test::UploadedFile.new(csv_tempfile.path, 'text/csv')
          } }
        end

        it 'retains the uploaded CSV in the re-rendered form' do
          patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

          expect(response).to have_http_status(:unprocessable_content)
          expect(rendered_page).to have_text('A structural metadata CSV has been uploaded.')
          expect(rendered_page).to have_field('multi_item_deposit_structure[structural_metadata_csv]', type: :hidden)
        end
      end
    end

    context 'when building the structure from the structural metadata CSV on the mount' do
      let(:owner) { user }
      let(:multi_item_deposit_action) do
        create(:multi_item_deposit_action, user: owner, step: 'structure', mount_path: mount_directory)
      end
      let(:csv_string) do
        "druid,sequence,filename,publish,preserve,rights_view,rights_download,rights_location\n" \
          "druid:bc123df4567,1,a.tif,yes,yes,world,world,\n"
      end
      let(:params) { { multi_item_deposit_structure: { structural_metadata_csv_choice: 'mount' } } }

      before { File.write(File.join(mount_directory, 'structural_metadata.csv'), csv_string) }

      it 'saves the CSV read from the mount and starts structuring' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(multi_item_deposit_action.reload).to be_structuring
        expect(multi_item_deposit_action).to have_attributes(structural_metadata_csv: csv_string,
                                                             structural_metadata_csv_source: 'mount')
      end
    end

    context 'when building the structure without a structural metadata CSV' do
      let(:owner) { user }
      let(:multi_item_deposit_action) do
        create(:multi_item_deposit_action, user: owner, step: 'structure', structural_metadata_csv: 'druid',
                                           structural_metadata_csv_source: 'upload')
      end
      let(:params) do
        { multi_item_deposit_structure: { structural_metadata_csv_choice: 'none', publish_preserve_all: 'true' } }
      end

      it 'clears the CSV, saves the publish / preserve setting, and starts structuring' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(multi_item_deposit_action.reload).to be_structuring
        expect(multi_item_deposit_action).to have_attributes(structural_metadata_csv: nil,
                                                             structural_metadata_csv_source: nil,
                                                             publish_preserve_all: true)
      end
    end

    context 'when returning to discovery from the structure step' do
      let(:owner) { user }
      let(:multi_item_deposit_action) do
        create(:multi_item_deposit_action, user: owner, step: 'structure', structuring_completed_at: Time.current,
                                           structural_metadata_csv: 'druid', structural_metadata_csv_source: 'upload')
      end

      before { create(:item_deposit_action, multi_item_deposit_action:) }

      it 'moves to the discovery step without discarding anything' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params: { commit: 'previous' })

        expect(multi_item_deposit_action.reload).to be_discovery_step
        expect(multi_item_deposit_action).to have_attributes(structural_metadata_csv: 'druid',
                                                             structuring_completed_at: be_present)
        expect(multi_item_deposit_action.item_deposit_actions.count).to eq(1)
        expect(batch_class).not_to have_received(:enqueue)
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when proceeding after structuring succeeded' do
      let(:owner) { user }
      let(:multi_item_deposit_action) do
        create(:multi_item_deposit_action, user: owner, step: 'structure', structuring_completed_at: Time.current)
      end

      before do
        create(:item_deposit_action, multi_item_deposit_action:, content_type_structure_warnings: ['No images'])
      end

      it 'moves to the deposit step without restarting structuring' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params: { commit: 'next' })

        expect(multi_item_deposit_action.reload).to be_deposit_step
        expect(batch_class).not_to have_received(:enqueue)
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when proceeding after structuring found errors' do
      let(:owner) { user }
      let(:multi_item_deposit_action) do
        create(:multi_item_deposit_action, user: owner, step: 'structure', structuring_completed_at: Time.current)
      end

      before do
        create(:item_deposit_action, multi_item_deposit_action:, structural_csv_errors: ['Row 2: Missing filename'])
      end

      it 'stays in the structure step' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params: { commit: 'next' })

        expect(multi_item_deposit_action.reload).to be_structure_step
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when building the structure with OCR but no languages' do
      let(:owner) { user }
      let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, step: 'structure') }
      let(:params) { { multi_item_deposit_structure: { perform_ocr: 'true', ocr_languages: [''] } } }

      before do
        create(:item_deposit_action, multi_item_deposit_action:, content_type: 'image')
      end

      it 'renders the structure page with errors' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_css('#multi_item_deposit_structure_ocr_languages_error',
                                          text: "can't be blank")
        expect(multi_item_deposit_action.reload).not_to be_structuring
        expect(multi_item_deposit_action.perform_ocr).to be false
        expect(batch_class).not_to have_received(:enqueue)
      end
    end

    context 'when structuring is in progress' do
      let(:owner) { user }
      let(:multi_item_deposit_action) do
        create(:multi_item_deposit_action, user: owner, step: 'structure', structuring_state: 'structuring')
      end
      let(:params) { { multi_item_deposit_structure: { perform_ocr: 'true', ocr_languages: ['English'] } } }

      it 'does not restart structuring and redirects to the edit page' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
        expect(multi_item_deposit_action.reload.perform_ocr).to be false
        expect(batch_class).not_to have_received(:enqueue)
      end
    end

    context 'when depositing with a version description' do
      let(:owner) { user }
      let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, step: 'deposit') }
      let(:params) { { multi_item_deposit_deposit: { version_description: 'Fixed typos' } } }

      before do
        create(:item_deposit_action, multi_item_deposit_action:, initial_version: false)
      end

      it 'saves the version description, starts the deposit, and redirects to the edit page' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(multi_item_deposit_action.reload.version_description).to eq('Fixed typos')
        expect(multi_item_deposit_action).to be_initiating_depositing
        expect(MultiItemDeposit::DepositJob).to have_been_enqueued
          .with(multi_item_deposit_action:, effective_groups: [workgroup])
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when initiating the deposit is in progress' do
      let(:owner) { user }
      let(:multi_item_deposit_action) do
        create(:multi_item_deposit_action, user: owner, step: 'deposit',
                                           initiating_deposit_state: 'initiating_depositing')
      end
      let(:params) { { multi_item_deposit_deposit: { version_description: 'Fixed typos' } } }

      it 'does not restart the deposit and redirects to the edit page' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
        expect(multi_item_deposit_action.reload.version_description).to be_nil
        expect(MultiItemDeposit::DepositJob).not_to have_been_enqueued
      end
    end

    context 'when depositing without a version description' do
      let(:owner) { user }
      let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, step: 'deposit') }
      let(:params) { { multi_item_deposit_deposit: { version_description: '' } } }

      before do
        create(:item_deposit_action, multi_item_deposit_action:, initial_version: false)
      end

      it 'renders the deposit page with errors' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(response).to have_http_status(:unprocessable_content)
        expect(rendered_page).to have_css('#multi_item_deposit_deposit_version_description_error',
                                          text: "can't be blank")
        expect(multi_item_deposit_action.reload.version_description).to be_nil
        expect(MultiItemDeposit::DepositJob).not_to have_been_enqueued
      end
    end

    context 'when returning to structure from the deposit step' do
      let(:owner) { user }
      let(:multi_item_deposit_action) do
        create(:multi_item_deposit_action, user: owner, step: 'deposit', initiating_deposit_completed_at: Time.current)
      end
      let(:params) { { commit: 'previous', multi_item_deposit_deposit: { version_description: '' } } }

      before do
        create(:item_deposit_action, multi_item_deposit_action:, initial_version: false)
      end

      it 'moves to the structure step, clearing the deposit results, without saving the version description' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(multi_item_deposit_action.reload).to be_structure_step
        expect(multi_item_deposit_action.initiating_deposit_completed_at).to be_nil
        expect(multi_item_deposit_action.version_description).to be_nil
        expect(MultiItemDeposit::DepositJob).not_to have_been_enqueued
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when depositing initial versions' do
      let(:owner) { user }
      let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, step: 'deposit') }

      before do
        create(:item_deposit_action, multi_item_deposit_action:, initial_version: true)
      end

      it 'saves the initial version description' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action))

        expect(multi_item_deposit_action.reload.version_description).to eq('Initial version')
        expect(response).to redirect_to(edit_multi_item_deposit_action_path(multi_item_deposit_action))
      end
    end

    context 'when the multi-item deposit action belongs to another user' do
      let(:owner) { create(:user) }

      it 'denies access' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(multi_item_deposit_action.reload.description).to eq('My deposit')
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'structural_metadata_csv_template' do
    let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, step: 'structure') }
    let(:content) { create(:content, :mutable, druid: 'druid:bc123df4567') }

    before do
      create(:item_deposit_action, multi_item_deposit_action:, druid: 'druid:bc123df4567', content:)
      create(:content_file_binary, content:, filepath: 'image1.tif', mime_type: 'image/tiff')
    end

    context 'when the multi-item deposit action belongs to the user' do
      let(:owner) { user }

      it 'downloads the structural metadata CSV template' do
        get structural_metadata_csv_template_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq('text/csv')
        expect(response.headers['Content-Disposition']).to include('attachment; filename="structural_metadata.csv"')
        expect(response.body.lines.second).to eq("bc123df4567,,,,image1.tif,,,,,,,,image/tiff,,,,\n")
      end
    end

    context 'when the multi-item deposit action belongs to another user' do
      let(:owner) { create(:user) }

      it 'denies access' do
        get structural_metadata_csv_template_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
