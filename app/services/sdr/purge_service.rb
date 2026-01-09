# frozen_string_literal: true

module Sdr
  # Service for purging objects from SDR.
  class PurgeService
    def self.can_purge?(...)
      new(...).can_purge?
    end

    def self.purge(druid:, user_name:)
      new(druid:).purge(user_name:)
    end

    # Raised when an object cannot be purged.
    class CannotPurgeError < StandardError; end

    def initialize(druid:)
      @druid = druid
    end

    # @return [Boolean] true if object can be purged
    def can_purge?
      !Sdr::WorkflowService.submitted?(druid:)
    end

    def purge(user_name:)
      raise CannotPurgeError, 'Cannot purge an object after it is submitted' unless can_purge?

      Dor::Services::Client.object(druid).destroy(user_name:)
    end

    private

    attr_reader :druid
  end
end
