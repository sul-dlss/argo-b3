# frozen_string_literal: true

module Searchers
  # Searcher for counting the APOs with an agreement.
  class AgreementAdminPolicyCount
    def self.call(...)
      new(...).call
    end

    # @param agreement_druid [String]
    # @param user_scope [Permissions::UserScope] the permission scope of the requesting user
    # @return [Integer] number of APOs with the agreement
    def initialize(agreement_druid:, user_scope:)
      @agreement_druid = agreement_druid
      @user_scope = user_scope
    end

    # Only APOs are indexed with an agreement.
    def call
      QueryCount.call(query: "#{Search::Fields::AGREEMENT_DRUID}:\"#{agreement_druid}\"", user_scope:)
    end

    private

    attr_reader :agreement_druid, :user_scope
  end
end
