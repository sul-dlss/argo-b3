# frozen_string_literal: true

module Reports
  # Checks a slice of DROs for the Content errors that would block a Deposit, as the object page shows them.
  # Reads only: the Contents are built in memory and nothing is saved.
  class ContentErrorsSliceChecker
    COULD_NOT_BE_CHECKED = 'Could not be checked'

    def self.call(...)
      new(...).call
    end

    # @param druids [Array<String>] the druids of DROs
    def initialize(druids:)
      @druids = druids
      @cocina_objects = {}
      @contents = {}
    end

    # @return [Array<Array(String, String, String)>] the bare druid, content type, and errors of each object with errors
    def call
      druids.filter_map do |druid|
        row_for(druid:)
      rescue StandardError => e
        Rails.logger.error("Content errors sweep could not check #{druid}: #{e.class}: #{e.message}")
        [DruidSupport.bare_druid_from(druid), content_type_for(druid:), COULD_NOT_BE_CHECKED]
      end
    end

    private

    attr_reader :druids, :cocina_objects, :contents

    def row_for(druid:)
      return if registered_without_files?(druid:)

      errors = Contents::Validator.call(content: content_for(druid:), cocina_object: cocina_object_for(druid:)).errors
      return if errors.empty?

      [DruidSupport.bare_druid_from(druid), content_type_for(druid:), errors.join(' ')]
    end

    # An object missing from the batch, or in a failed batch (e.g., one object's cocina is invalid), is retrieved
    # on its own so that its own error is raised; the error is remembered so it isn't requested again.
    def cocina_object_for(druid:)
      raise retrieval_errors[druid] if retrieval_errors.key?(druid)

      cocina_objects[druid] ||= batch_cocina_objects[druid] || Sdr::Repository.find(druid:)
    rescue StandardError => e
      retrieval_errors[druid] = e
      raise
    end

    def retrieval_errors
      @retrieval_errors ||= {}
    end

    def batch_cocina_objects
      @batch_cocina_objects ||= begin
        Sdr::Repository.find_all(druids:)
      rescue StandardError => e
        Rails.logger.info("Content errors sweep retrieving objects one at a time: #{e.class}: #{e.message}")
        {}
      end
    end

    def content_for(druid:)
      contents[druid] ||= Contents::Builder.build(cocina_object: cocina_object_for(druid:))
    end

    def content_type_for(druid:)
      type = cocina_objects[druid]&.type
      type && UriSupport.last(uri: type)
    end

    # As on the object page, a Registered item (an open first version) with no files is not validated.
    def registered_without_files?(druid:)
      return false if files?(druid:)

      version_service = Sdr::VersionService.new(druid:, status: statuses_without_files.fetch(druid))
      version_service.open? && version_service.version == 1
    end

    def files?(druid:)
      content_for(druid:).content_file_sets.any? { |content_file_set| content_file_set.content_files.any? }
    end

    # Retrieved together, since objects without files may be common; a failure is remembered, not requested again.
    def statuses_without_files
      raise @statuses_error if @statuses_error

      @statuses_without_files ||= Sdr::VersionService.statuses(druids: druids_without_files)
    rescue StandardError => e
      @statuses_error = e
      raise
    end

    # Objects that can't be retrieved are left to fail when they are checked.
    def druids_without_files
      druids.reject do |druid|
        files?(druid:)
      rescue StandardError
        true
      end
    end
  end
end
