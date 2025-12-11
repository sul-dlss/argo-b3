# frozen_string_literal: true

# Controller for searches
class SearchController < SearchApplicationController
  def show
    Rails.logger.info("HEADERS: #{request.headers.to_h.inspect}")
  end
end
