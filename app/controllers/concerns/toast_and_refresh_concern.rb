# frozen_string_literal: true

# Concern for controllers whose actions show a toast and then refresh the page they were invoked from
# (e.g., pinning and unpinning).
#
# Turbo requests get a turbo stream that appends the toast and morph-refreshes the page, rather than a
# redirect carrying the toast in the flash. A page that periodically refreshes itself (e.g., the object
# show page) can otherwise have a refresh request land between setting the flash and following the redirect,
# consuming the flash so that the toast is never shown.
#
# Any page invoking these actions will want to include:
# <% content_for :head do %>
#   <meta name="turbo-refresh-method" content="morph">
#   <meta name="turbo-refresh-scroll" content="preserve">
# <% end %>
module ToastAndRefreshConcern
  extend ActiveSupport::Concern

  private

  # @param fallback_location [String] where a non-Turbo request is redirected when there is no referer
  def toast_and_refresh(title, fallback_location: root_path)
    respond_to do |format|
      format.turbo_stream do
        # request_id is cleared since Turbo ignores a refresh carrying the id of a request the page itself made.
        render turbo_stream: [helpers.render(Elements::FlashToastComponent.new(title:)),
                              turbo_stream.refresh(request_id: nil)]
      end
      format.html do
        flash[:toast] = title
        redirect_back_or_to fallback_location, status: :see_other
      end
    end
  end
end
