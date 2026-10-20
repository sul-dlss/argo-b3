# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Multi-item deposit' do
  let(:workgroup) { 'sdr:test-workgroup' }
  let!(:user) { create(:user, groups: [workgroup]) }
  let(:apo_druid) { 'druid:hv992ry2431' }
  let(:mount_path) { Dir.mktmpdir(nil, Rails.root.join('tmp')) }
  let(:manifest_directory) { Dir.mktmpdir }
  let(:version_service) do
    instance_double(Sdr::VersionService, open?: false, openable?: true, closeable?: true, version: 2)
  end
  # The test database has no queue tables, so a verifying double (which loads the schema) cannot be used.
  # The block enqueues to the test adapter.
  let(:batch_class) { double('SolidQueue::Batch') } # rubocop:disable RSpec/VerifiedDoubles

  before do
    create(:permission, :edit, workgroup:, target_druid: apo_druid)

    %w[folder1 folder2].each do |folder_name|
      FileUtils.mkdir_p(File.join(mount_path, folder_name))
      File.write(File.join(mount_path, folder_name, "#{folder_name}.txt"), folder_name)
    end

    allow(Sdr::Repository).to receive(:find) do |druid:|
      build(:dro_with_metadata, id: druid, admin_policy_id: apo_druid)
    end
    allow(Sdr::VersionService).to receive(:new).and_return(version_service)
    stub_const('SolidQueue::Batch', batch_class)
    allow(batch_class).to receive(:enqueue).and_yield
    allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)

    sign_in user
  end

  after do
    FileUtils.rm_rf(mount_path)
    FileUtils.rm_rf(manifest_directory)
  end

  def write_manifest(filename, csv)
    File.join(manifest_directory, filename).tap { |manifest_path| File.write(manifest_path, csv) }
  end

  it 'checks the manifest, discovers files, and proceeds to structure' do
    visit root_path
    click_on 'Deposit multiple items'

    expect(page).to have_css('h1', text: 'Multi-item deposit')
    multi_item_deposit_action = MultiItemDepositAction.last

    fill_in 'Describe this deposit', with: 'My multi-item deposit'
    expect(page).to have_field('Upload from a computer', checked: true)
    attach_file 'Upload manifest file',
                write_manifest('invalid.csv', "druid,folder_name\nbc123df4567,folder1\ncd234fg5678,\n")
    fill_in 'Mount path', with: mount_path
    click_on 'Discover files and check manifest'

    # The manifest fails validation, so discovery does not start.
    expect(page).to have_text('Blank folder_name in rows: 3.')
    expect(page).to have_field('Describe this deposit', with: 'My multi-item deposit')
    expect(page).to have_field('Mount path', with: mount_path)
    expect(multi_item_deposit_action.item_deposit_actions).to be_empty

    attach_file 'Upload manifest file',
                write_manifest('manifest.csv', "druid,folder_name\nbc123df4567,folder1\ncd234fg5678,folder2\n")
    fill_in 'Mount path', with: File.join(mount_path, 'missing')
    click_on 'Discover files and check manifest'

    # The mount path fails validation, but the uploaded manifest is retained.
    expect(page).to have_text('does not exist')
    expect(page).to have_text('A manifest has been uploaded.')

    fill_in 'Mount path', with: mount_path
    click_on 'Discover files and check manifest'

    expect(page).to have_text('Processing...')
    expect(multi_item_deposit_action.reload).to be_discovering
    expect(multi_item_deposit_action.item_deposit_actions.pluck(:druid, :path))
      .to contain_exactly(['druid:bc123df4567', 'folder1'], ['druid:cd234fg5678', 'folder2'])

    # Run the batch's jobs, which the test adapter has only enqueued.
    multi_item_deposit_action.item_deposit_actions.each do |item_deposit_action|
      MultiItemDeposit::DiscoverFilesJob.perform_now(item_deposit_action:, effective_groups: user.groups)
    end
    MultiItemDeposit::DiscoverFilesFinishJob.perform_now(multi_item_deposit_action:)

    # The wait page refreshes to show the results.
    expect(page).to have_css('h2', text: 'Results of checking manifest')
    expect(page).to have_css('.alert-success', text: 'No errors with manifest')
    expect(page).to have_no_css('.alert-danger')
    expect(page).to have_no_table('Error details')
    expect(page).to have_field('Upload from a computer', checked: true)
    expect(page).to have_text('A manifest has been uploaded.')

    click_on 'Next'

    expect(page).to have_css('h1', text: 'Multi-item deposit')
    expect(page).to have_no_field('Mount path')
    expect(multi_item_deposit_action.reload).to be_structure_step
  end
end
