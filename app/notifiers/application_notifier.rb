# frozen_string_literal: true

# Superclass of all Notifiers, one per kind of Notification.
# A Notifier's notifications render from i18n using the event's params (no stored HTML). Each Notifier defines
# in its `notification_methods`:
# - `title`: the Notification's title.
# - `text`: the toast's text, linking to the subject (`subject_link`).
# - `subject_label` and `subject_path`: the subject's link text and path, for the list of recent notifications.
# - `detail`: the detail or error summary shown below the title in the list of recent notifications, or nil.
# - `error?` (optional): whether the Notification reports an error.
#
# A Notifier that emails names the email switch covering its emails with `email_notifier_kind`, and skips the email
# when the recipient has turned that switch off with `unless: :email_turned_off?` (or a method that calls it).
class ApplicationNotifier < Noticed::Event
  # One of EmailOptOut::NOTIFIER_KINDS, for Notifiers that email.
  class_attribute :email_notifier_kind

  # Evaluated when the email is due, so turning the switch off cancels a pending delayed email, and turning it on
  # does not resend emails it skipped.
  # @return [Boolean] whether the recipient has turned off this Notifier's emails
  def email_turned_off?(notification)
    !notification.recipient.email_on?(email_notifier_kind)
  end

  notification_methods do
    # @return [Boolean] whether the Notification reports an error
    def error?
      false
    end

    private

    # @return [String] the count with thousands delimiters
    def delimited(count)
      ActiveSupport::NumberHelper.number_to_delimited(count)
    end

    # @return [ActiveSupport::SafeBuffer] a link to the Notification's subject
    def subject_link(link_text, path)
      ActionController::Base.helpers.link_to(link_text, path, class: 'link-light text-decoration-underline')
    end
  end
end
