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
  let(:status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, open?: false, openable?: true)
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
    allow(version_service).to receive(:open) { build(:dro_with_metadata).new(lock: 'opened-lock') }
    allow(Sdr::VersionService).to receive(:statuses) { |druids:| druids.index_with { status } }
    allow(Searchers::ItemByDruid).to receive(:call) do |druids:, **|
      druids.map { |druid| SearchResults::Item.new(solr_doc: build(:solr_item, druid:)) }
    end
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

  def run_structure_jobs(multi_item_deposit_action)
    multi_item_deposit_action.item_deposit_actions.each do |item_deposit_action|
      MultiItemDeposit::StructureJob.perform_now(item_deposit_action:)
    end
    MultiItemDeposit::StructureFinishJob.perform_now(multi_item_deposit_action:)
  end

  # The objects' locks are those found at discovery, except for any changed since.
  def run_deposit_job(multi_item_deposit_action, changed_druids: [])
    allow(Sdr::Repository).to receive(:find_all) do |druids:|
      druids.index_with do |druid|
        cocina_object = build(:dro_with_metadata, id: druid, admin_policy_id: apo_druid)
        changed_druids.include?(druid) ? cocina_object.new(lock: 'changed-lock') : cocina_object
      end
    end
    MultiItemDeposit::DepositJob.perform_now(multi_item_deposit_action: multi_item_deposit_action.reload,
                                             effective_groups: user.groups)
  end

  it 'checks the manifest, discovers files, structures, and deposits' do
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

    expect(page).to have_text("Processing Multi-item deposit #{multi_item_deposit_action.id}: My multi-item deposit...")
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

    # No CSV is on the mount and the items cannot be OCRed.
    expect(page).to have_no_field('Yes, use structural metadata CSV found in file location')
    expect(page).to have_no_css('legend', text: 'Run OCR?')
    expect(page).to have_field('No', checked: true)
    expect(page).to have_field('Upload structural metadata CSV', disabled: true)
    expect(page).to have_button('Next', disabled: true)

    choose 'Yes, upload a structural metadata CSV'
    expect(page).to have_field('Default by file type', disabled: true)
    attach_file 'Upload structural metadata CSV', write_manifest('structural.csv', "druid,sequence\nbc123df4567,1\n")
    click_on 'Check files'

    # The CSV fails validation, so structuring does not start.
    expect(page).to have_text('missing headers: filename')
    expect(multi_item_deposit_action.reload).not_to be_structuring

    choose 'No'
    choose 'Publish and preserve all files'
    click_on 'Check files'

    expect(page).to have_text("Processing Multi-item deposit #{multi_item_deposit_action.id}: My multi-item deposit...")
    expect(multi_item_deposit_action.reload).to be_structuring
    expect(multi_item_deposit_action).to have_attributes(structural_metadata_csv: nil, publish_preserve_all: true)

    run_structure_jobs(multi_item_deposit_action)

    # The wait page refreshes to show the results.
    expect(page).to have_css('h2', text: 'Results of checking files')
    summary_rows = page.find('table[aria-label="Summary"]').all('tbody tr')
    expect(summary_rows.map { |row| row.all('td').map { |cell| cell.text.strip } })
      .to eq([%w[bc123df4567 1 object redeposit], %w[cd234fg5678 1 object redeposit]])
    expect(page).to have_field('Publish and preserve all files', checked: true)

    # Returning to discovery discards nothing.
    click_on 'Previous'

    expect(page).to have_css('h2', text: 'Results of checking manifest')
    expect(multi_item_deposit_action.reload).to be_discovery_step

    click_on 'Next'

    expect(page).to have_css('h2', text: 'Results of checking files')

    click_on 'Next'

    expect(page).to have_css('h1', text: 'Multi-item deposit')
    expect(multi_item_deposit_action.reload).to be_deposit_step

    # The items are redeposits, so a version description is required.
    expect(page).to have_field('Version description', disabled: false)
    click_on 'Check version status and deposit'

    expect(page).to have_css('#multi_item_deposit_deposit_version_description_error', text: "can't be blank")
    expect(multi_item_deposit_action.reload).not_to be_initiating_depositing

    # Returning to structure keeps the structure results.
    click_on 'Previous'

    expect(page).to have_css('h2', text: 'Results of checking files')
    expect(multi_item_deposit_action.reload).to be_structure_step

    click_on 'Next'

    fill_in 'Version description', with: 'Adding files'
    click_on 'Check version status and deposit'

    expect(page).to have_text("Processing Multi-item deposit #{multi_item_deposit_action.id}: My multi-item deposit...")
    expect(multi_item_deposit_action.reload).to be_initiating_depositing
    expect(multi_item_deposit_action.version_description).to eq('Adding files')
    expect(MultiItemDeposit::DepositJob).to have_been_enqueued

    run_deposit_job(multi_item_deposit_action, changed_druids: ['druid:cd234fg5678'])

    # The wait page refreshes to show the errors, and nothing is deposited.
    expect(page).to have_css('h2', text: 'Results of checking version status')
    error_rows = page.find('table[aria-label="Error details"]').all('tbody tr')
    expect(error_rows.map { |row| row.all('td').map { |cell| cell.text.strip } })
      .to eq([['cd234fg5678', 'Object changed since discovery; re-run Discover files']])
    expect(page).to have_field('Version description', with: 'Adding files')
    expect(version_service).not_to have_received(:open)

    click_on 'Check version status and deposit'

    expect(page).to have_text("Processing Multi-item deposit #{multi_item_deposit_action.id}: My multi-item deposit...")

    run_deposit_job(multi_item_deposit_action)

    # The wait page refreshes to the show page once the deposit is submitted.
    expect(page).to have_css('h2', text: 'Deposit status')
    expect(page).to have_text('My multi-item deposit')
    deposit_status_rows = page.find('table[aria-label="Deposit status"]').all('tbody tr')
    expect(deposit_status_rows.map { |row| row.all('td').map { |cell| cell.text.strip } })
      .to eq([['bc123df4567', 'Staging files'], ['cd234fg5678', 'Staging files']])
    expect(deposit_status_rows[0]).to have_link('bc123df4567', href: '/objects/druid:bc123df4567')
    expect(multi_item_deposit_action.reload).to be_submitted_step
    expect(version_service).to have_received(:open).twice
    expect(StageFilesJob).to have_been_enqueued.twice
  end
end
