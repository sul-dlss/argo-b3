# frozen_string_literal: true

module Contents
  # Stages, from Stacks, the deposited files that are now preserved but that Preservation does not have
  # (e.g., a shelved file changed from preserve=no to preserve=yes), so that accessioning can preserve them.
  class StacksStager
    # Raised, after attempting every file, when any file could not be staged.
    class Error < StandardError
      def initialize(filepaths:)
        @filepaths = filepaths
        super("Could not stage from Stacks: #{filepaths.join(', ')}")
      end

      attr_reader :filepaths
    end

    # Raised when a file from Stacks does not match the deposited file's MD5.
    class IntegrityError < StandardError; end

    def self.call(...)
      new(...).call
    end

    # @param [Content] content
    # @param [String] staging_location
    def initialize(content:, staging_location:)
      @content = content
      @staging_location = staging_location
    end

    # @raise [Error] if any file could not be staged
    def call
      content_file_binaries = unpreserved_content_file_binaries
      return if content_file_binaries.empty?

      failed_filepaths = content_file_binaries.reject { |content_file_binary| stage(content_file_binary) }
                                              .map(&:filepath)
      raise Error.new(filepaths: failed_filepaths) if failed_filepaths.any?
    end

    private

    attr_reader :content, :staging_location

    delegate :druid, to: :content

    def unpreserved_content_file_binaries
      candidates = content.content_file_binaries.associated.file_location_deposited
                          .where(content_files: { preserve: true }).to_a
      return [] if candidates.empty?

      candidates.reject { |content_file_binary| preserved_md5s.include?(content_file_binary.md5_digest) }
    end

    # Preservation de-duplicates by signature, so a file is preserved if any preserved content file has its MD5.
    def preserved_md5s
      @preserved_md5s ||= Preservation::Client.objects.signature_catalog(druid).entries
                                              .select { |entry| entry.group_id == 'content' }
                                              .to_set { |entry| entry.signature.md5 }
    rescue Preservation::Client::NotFoundError
      Set.new
    end

    # @return [Boolean] true if staged
    def stage(content_file_binary)
      staging_filepath = StagingSupport.staging_filepath(druid:, filepath: content_file_binary.filepath,
                                                         staging_location:)
      download(content_file_binary:, staging_filepath:)
      content_file_binary.file_location_stage!
      true
    rescue Sdr::StacksFile::NotFoundError, Faraday::Error, IntegrityError => e
      Honeybadger.notify(e, context: { druid:, filepath: content_file_binary.filepath })
      false
    end

    # Downloads to a temporary file, moved into place only once its MD5 is verified.
    def download(content_file_binary:, staging_filepath:)
      FileUtils.mkdir_p(File.dirname(staging_filepath))
      temp_filepath = "#{staging_filepath}.stacks-download"
      md5 = Digest::MD5.new
      File.open(temp_filepath, 'wb') do |file|
        Sdr::StacksFile.stream(druid:, filepath: content_file_binary.filepath) do |chunk|
          md5.update(chunk)
          file.write(chunk)
        end
      end
      verify_md5!(content_file_binary:, md5: md5.hexdigest)
      File.rename(temp_filepath, staging_filepath)
    ensure
      FileUtils.rm_f(temp_filepath)
    end

    def verify_md5!(content_file_binary:, md5:)
      return if md5 == content_file_binary.md5_digest

      raise IntegrityError, "MD5 of #{content_file_binary.filepath} from Stacks (#{md5}) does not match " \
                            "#{content_file_binary.md5_digest}"
    end
  end
end
