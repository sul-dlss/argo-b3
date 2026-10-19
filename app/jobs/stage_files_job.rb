# frozen_string_literal: true

# Job that copies files to staging, generates fixities, determines mimetype,
# updates the object, and optionally accessions.
class StageFilesJob < ApplicationJob
  # @param [Content] content the content whose files should be staged
  # @param [User] user the user initiating the staging
  # @param [Boolean] accession whether to close the version and accession after staging
  def perform(content:, user:, accession: false)
    @content = Content.with_structural_associations.find(content.id) # Pre-fetching for efficiency.
    @user = user

    check_lock! # Check cocina lock version and raise if optimistic lock problem
    Contents::ExternalIdentifierMinter.call(content:) # Mint external identifiers for new files/filesets
    analyze! # Generate digests, size, and mimetypes
    stage! # Copy to staging
    updated_cocina_object = update_sdr!(content:)
    accession!(content:, cocina_object: updated_cocina_object) if accession
    content.staging_completed!

    perform_broadcast
  rescue StandardError => e
    handle_failure(error: e, content:, user:)
  end

  attr_reader :content, :user

  delegate :druid, to: :content

  def cocina_object
    @cocina_object = Sdr::Repository.find(druid:)
  end

  def stageable_content_file_binaries
    # Globus to be added.
    content.content_file_binaries
           # Binaries that are not part of the structure are not deposited, so they are not staged.
           # This shouldn't happen, but just in case.
           .associated
           .where(file_location: %w[attached mount])
           .includes(file_attachment: :blob)
  end

  def check_lock!
    return if content.lock == cocina_object.lock

    raise "Lock mismatch for #{druid}. Content: #{content.lock}. Cocina object: #{cocina_object.lock}"
  end

  # The Content follows the object to its new lock right away, so that a later failure leaves a mutable Content
  # to retry with.
  def update_sdr!(content:)
    Sdr::Repository.update(
      cocina_object: CocinaObjectMutators::StructuralMutator.call(cocina_object:, content:),
      user_name: user.sunetid
    ).tap { |updated_cocina_object| content.update!(lock: updated_cocina_object.lock) }
  end

  # The Content becomes immutable only once accessioning has started, so that it stays mutable if accessioning fails.
  def accession!(content:, cocina_object:)
    Sdr::Repository.accession(cocina_object:, user_name: user.sunetid, context: content.workflow_context)
    make_immutable!(content:, lock: cocina_object.lock)
  end

  # An unchanged structure leaves the lock unchanged, so this Content supersedes the existing immutable Content.
  def make_immutable!(content:, lock:)
    Content.transaction do
      Content.where(druid:, lock:, immutable: true).where.not(id: content.id).find_each(&:destroy!)
      content.update!(lock:, immutable: true)
    end
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

  # Uses the arguments passed to #perform, since the failure may have happened before they were assigned.
  def handle_failure(error:, content:, user:)
    Rails.logger.error(error.full_message)
    Honeybadger.notify(error)

    # Discards any unsaved changes from the failure, so that recording it does not fail again.
    content.reload
    content.staging_errored! if content.staging?
    Turbo::StreamsChannel.broadcast_refresh_to('objects', content.druid)
    broadcast_toast(title: I18n.t('edit.items.new.toasts.staging_failed'),
                    text: I18n.t('edit.items.new.toasts.staging_failed_text', email: Settings.support_email),
                    user:, disappearing: false, variant: :red)
  end
end
