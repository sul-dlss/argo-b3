# frozen_string_literal: true

# Concern for controllers whose responses are only turbo-frame content (rendered without a layout).
# A request that did not come from a turbo-frame (e.g., a pagination link opened in a new tab)
# is redirected to the full search page for the same search form.
module TurboFrameOnlyConcern
  extend ActiveSupport::Concern

  included do
    before_action :redirect_to_full_page, unless: :turbo_frame_request?
  end

  private

  def redirect_to_full_page
    redirect_to @search_form
  end
end
