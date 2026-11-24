# frozen_string_literal: true

# Superclass of all Notifiers, one per kind of Notification.
# A Notifier's notifications render their title and text (linking to the subject) from i18n using the event's params
# (no stored HTML): each Notifier defines `title` and `text` in its `notification_methods`, and overrides `error?`
# when the Notification can report an error.
class ApplicationNotifier < Noticed::Event
  notification_methods do
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
