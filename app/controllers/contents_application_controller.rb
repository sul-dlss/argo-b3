# frozen_string_literal: true

# Base controller for managing content.
class ContentsApplicationController < ApplicationController
  COCINA_HASH_EXPIRATION = 1.hour

  include TokenConcern

  # The strategy is to authorize on ContentsController#edit, but not repeat authorization
  # for the other actions, which verify the signed content id instead.
  self.token_purpose = 'contents'

  private

  # @return [Hash] the cached cocina hash for the druid/lock, fetching from SDR on a miss
  def fetch_cocina_hash(druid:, lock:)
    Rails.cache.fetch(cocina_hash_cache_key(druid:, lock:), expires_in: COCINA_HASH_EXPIRATION) do
      cocina_object = Sdr::Repository.find(druid:)
      CacheSupport.cacheable_cocina_object(cocina_object:)
    end
  end

  def cache_cocina_hash(cocina_object:)
    cache_key = cocina_hash_cache_key(druid: cocina_object.externalIdentifier, lock: cocina_object.lock)
    Rails.cache.write(cache_key, CacheSupport.cacheable_cocina_object(cocina_object:),
                      expires_in: COCINA_HASH_EXPIRATION)
  end

  def cocina_hash_cache_key(druid:, lock:)
    "contents/cocina-hash/#{druid}/#{lock}"
  end
end
