# frozen_string_literal: true

# Broadcasts a toast to a user's open pages.
class ToastBroadcaster
  # @param [String] title toast message to display
  # @param [User] user recipient of the toast
  # @param [Boolean] disappearing whether the toast auto-dismisses
  # @param [String] text optional body text for the toast (may be HTML safe)
  # @param [Symbol] variant the toast color variant (e.g., :red for errors)
  def self.call(title:, user:, disappearing: true, text: nil, variant: :black)
    component = SdrViewComponents::Elements::ToastComponent.new(title:, text:, variant:, disappearing:)
    Turbo::StreamsChannel.broadcast_append_to('notifications', user,
                                              target: 'toast-container',
                                              html: ApplicationController.render(component, layout: false))
  end
end
