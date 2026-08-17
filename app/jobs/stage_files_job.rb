# frozen_string_literal: true

# Job that copies files to staging, generates fixities, determines mimetype,
# updates the object, and optionally closes version.
class StageFilesJob < ApplicationJob
  # @param [Content] content the content whose files should be staged
  # @param [User] user the user initiating the staging
  # @param [Boolean] accession whether to close the version and accession after staging
  def perform(content:, user:, accession: false)
    @content = content
    @user = user

    check_lock! # Check cocina lock version and raise if optimistic lock problem
    Contents::ExternalIdentifierMinter.call(content:) # Mint external identifiers for new files/filesets
    analyze! # Generate digests, size, and mimetypes
    stage! # Copy to staging
    # Update SDR
    updated_cocina_object = Sdr::Repository.update(
      cocina_object: CocinaObjectMutators::StructuralMutator.call(cocina_object:, content:),
      user_name: user.sunetid
    )

    content.update!(lock: updated_cocina_object.lock, immutable: true)

    # Optionally start accessioning.
    Sdr::Repository.accession(druid:, user_name: user.sunetid) if accession
    content.staging_completed!

    perform_broadcast
  end

  attr_reader :content, :user

  delegate :druid, to: :content

  def cocina_object
    @cocina_object = Sdr::Repository.find(druid:)
  end

  def stageable_content_file_binaries
    # Globus and mount to be added.
    content.content_file_binaries.where(file_location: ['attached'])
  end

  def check_lock!
    return if content.lock == cocina_object.lock

    raise "Lock mismatch for #{druid}. Content: #{content.lock}. Cocina object: #{cocina_object.lock}"
  end

  def analyze!
    stageable_content_file_binaries.find_each do |content_file_binary|
      Contents::Analyzer.call(content_file_binary:)
    end
  end

  def stage!
    stageable_content_file_binaries.find_each do |content_file_binary|
      filepath = content_file_binary.filepath_on_disk
      staging_filepath = StagingSupport.staging_filepath(druid:, filepath: content_file_binary.filepath)
      create_directory(staging_filepath)
      FileUtils.cp filepath, staging_filepath
      content_file_binary.file_location_stage!
    end
  end

  def create_directory(filepath)
    FileUtils.mkdir_p File.dirname(filepath)
  end

  def perform_broadcast
    Turbo::StreamsChannel.broadcast_refresh_to('objects', druid)

    broadcast_toast(title: I18n.t('edit.items.new.toasts.staging_completed'), user:, disappearing: true)
  end
end
