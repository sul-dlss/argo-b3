# frozen_string_literal: true

# Superclass of all Notifiers, one per kind of Notification.
# A Notifier's notifications render their title, text, and link from i18n using the event's params (no stored HTML),
# by implementing the methods in ApplicationNotifier::Notification.
class ApplicationNotifier < Noticed::Event
  notification_methods do
    # @return [String] the Notification's title
    def title
      raise NotImplementedError
    end

    # @return [String] the Notification's text, linking to its subject
    def text
      raise NotImplementedError
    end

    # @return [Boolean] whether the Notification reports an error
    def error?
      false
    end

    private

    # @return [ActiveSupport::SafeBuffer] a link to the Notification's subject
    def subject_link(link_text, path)
      ActionController::Base.helpers.link_to(link_text, path, class: 'link-light text-decoration-underline')
    end
  end
end
