# frozen_string_literal: true

module Sdr
  # Service for getting the title for an object.
  # This is helpful for getting the titles for collections and admin policies since cocina objects
  # only record the druids.
  class TitleService
    EXPIRES_IN = 60.minutes

    def self.call(...)
      new(...).call
    end

    def initialize(druid:)
      @druid = druid
    end

    # @return [String] the title for the object
    # @raise [Sdr::Repository::NotFound] if the object is not found
    def call
      Rails.cache.fetch(cache_key, expires_in: EXPIRES_IN) do
        CocinaModels::PresenterFactory.find_and_build(druid, structural: false).title
      end
    end

    private

    attr_reader :druid

    def cache_key
      "title-#{druid}"
    end
  end
end
