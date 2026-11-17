# frozen_string_literal: true

module BulkActions
  # Job to zip the files of an object, from its staged files, preservation, or stacks.
  class DownloadFilesJob < DruidsJob
    def perform_bulk_action
      super
      # The item stops when cancelled while zipping, so the cancellation is recorded here.
      cancel! if cancelling?
    end

    # Zips the files of a single object
    class JobItem < BaseJobItem
      # Raised to stop zipping when the bulk action is cancelled.
      class Cancelled < StandardError; end

      def perform
        return unless check_read_ability?
        return failure!(message: 'No files are available to download') if downloadable_files.empty?
        return failure!(message: too_large_message) if downloadable_files.too_large?

        report_zipped(failed_count: write_zip)
      rescue Cancelled
        FileUtils.rm_f(part_filepath)
      end

      private

      def report_zipped(failed_count:)
        zipped_count = content_files.size - failed_count
        return success!(message: "Zipped #{zipped_count} files") if failed_count.zero?

        failure!(message: "Zipped #{zipped_count} of #{content_files.size} files")
      end

      # @return [Integer] the number of files that could not be zipped
      # @raise [Cancelled] if the bulk action is cancelled while zipping
      def write_zip
        failed_count = 0
        Zip::OutputStream.open(part_filepath) do |zip|
          content_files.each do |content_file|
            raise Cancelled if job.cancelling?

            failed_count += 1 unless add_file(zip:, content_file:)
          end
        end
        File.rename(part_filepath, zip_filepath)
        failed_count
      end

      # @return [Boolean] whether the file was added
      def add_file(zip:, content_file:)
        download_filepath = File.join(output_directory, "#{SecureRandom.uuid}.download")
        return false unless downloaded?(content_file:, download_filepath:)

        zip.put_next_entry(content_file.filepath)
        File.open(download_filepath, 'rb') { |file| IO.copy_stream(file, zip) }
        true
      ensure
        FileUtils.rm_f(download_filepath)
      end

      # Downloads the file, logging it if it could not be downloaded or is not the expected size.
      def downloaded?(content_file:, download_filepath:)
        FileDownloadService.to_file(druid:, filepath: content_file.filepath, destination: download_filepath)
        size_matches?(content_file:, download_filepath:)
      rescue FileDownloadService::NotFoundError => e
        log_file_failure(content_file:, message: e.message)
        false
      rescue StandardError => e
        Rails.logger.error(e.full_message)
        Honeybadger.notify(e)
        log_file_failure(content_file:, message: "#{e.class} #{e.message}")
        false
      end

      def size_matches?(content_file:, download_filepath:)
        return true if content_file.size.nil?

        actual_size = File.size(download_filepath)
        return true if actual_size == content_file.size

        log_file_failure(content_file:, message: "expected #{content_file.size} bytes, but got #{actual_size}")
        false
      end

      def log_file_failure(content_file:, message:)
        log(job.delimited_log_message(druid:,
                                      message: "Error: Could not download #{content_file.filepath}: #{message}"))
      end

      def downloadable_files
        @downloadable_files ||= DownloadableFiles.new(
          content: Contents::Builder.find_or_create(cocina_object:),
          file_availability: FileAvailability.new(druid:, cocina_version: cocina_object.version)
        )
      end

      delegate :content_files, to: :downloadable_files

      def too_large_message
        "The files total #{number_to_human_size(downloadable_files.total_size)}, " \
          "more than the #{number_to_human_size(DownloadableFiles.max_size)} that can be downloaded"
      end

      delegate :number_to_human_size, to: ActiveSupport::NumberHelper

      def output_directory
        job.bulk_action.output_directory
      end

      def zip_filepath
        File.join(output_directory, "#{DruidSupport.bare_druid_from(druid)}.zip")
      end

      def part_filepath
        "#{zip_filepath}.part"
      end
    end
  end
end
