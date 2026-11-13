# frozen_string_literal: true

# Base controller for managing content.
class ContentsApplicationController < ApplicationController
  COCINA_HASH_EXPIRATION = 1.hour

  include TokenConcern

  # The strategy is to authorize on ContentsController#edit, but not repeat authorization
  # for the other actions, which verify the signed content id instead.
  self.token_purpose = 'contents'

  private

  # Changes are refused while the content is busy (see Content#busy?), e.g., when made from a stale tab. The page is
  # refreshed, which then shows that the content is busy.
  # @param content [Content]
  # @return [Boolean] true if the change was refused
  def refused_while_busy?(content)
    return false unless content.busy?

    render_page_refresh(status: :conflict)
    true
  end

  # A redirect from inside a turbo frame stays in the frame, so the whole page is refreshed instead.
  # request_id is cleared since Turbo ignores a refresh carrying the id of a request the page itself made.
  # @param toast [String, nil] a toast to append, since a flash could be consumed before the refresh
  def render_page_refresh(toast: nil, status: :ok)
    streams = [turbo_stream.refresh(request_id: nil)]
    streams.unshift(helpers.render(Elements::FlashToastComponent.new(title: toast))) if toast
    render turbo_stream: streams, status:
  end

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
