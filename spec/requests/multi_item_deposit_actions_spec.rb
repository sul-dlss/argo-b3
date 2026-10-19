# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Multi-item deposit actions' do
  let(:workgroup) { 'sdr:test-workgroup' }
  let(:user) { create(:user, groups: [workgroup]) }
  let(:rendered_page) { Capybara.string(response.body) }

  before do
    sign_in(user)
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

  describe 'edit' do
    let(:multi_item_deposit_action) { create(:multi_item_deposit_action, user: owner, description: 'My deposit') }

    context 'when the multi-item deposit action belongs to the user' do
      let(:owner) { user }

      it 'renders the edit page' do
        get edit_multi_item_deposit_action_path(multi_item_deposit_action)

        expect(response).to have_http_status(:ok)
        expect(rendered_page).to have_css('h1', text: 'Multi-item deposit')
        expect(rendered_page).to have_field('Describe this deposit', with: 'My deposit')
        expect(rendered_page).to have_button('Discover files and check manifest')
        expect(rendered_page).to have_link('Cancel', href: root_path)
        expect(rendered_page).to have_field('Upload from a computer', type: 'radio', checked: true)
        expect(rendered_page).to have_field('Include with your files below', type: 'radio')
        expect(rendered_page).to have_field('Upload manifest file', type: 'file')
        expect(rendered_page).to have_field('Globus', type: 'radio', disabled: true)
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
        expect(rendered_page).to have_no_field('Mount path')
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

    context 'when the multi-item deposit action belongs to another user' do
      let(:owner) { create(:user) }

      it 'denies access' do
        patch(multi_item_deposit_action_path(multi_item_deposit_action), params:)

        expect(multi_item_deposit_action.reload.description).to eq('My deposit')
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
