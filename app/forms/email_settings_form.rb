# frozen_string_literal: true

# Form for a user's email settings: an on / off switch for each kind of Notification email.
class EmailSettingsForm < ApplicationForm
  EmailOptOut::NOTIFIER_KINDS.each do |notifier_kind|
    attribute notifier_kind, :boolean, default: true
  end

  # @param user [User]
  # @return [EmailSettingsForm] the user's current settings
  def self.for(user)
    opted_out_kinds = user.email_opt_outs.pluck(:notifier_kind)
    new(EmailOptOut::NOTIFIER_KINDS.index_with { |notifier_kind| opted_out_kinds.exclude?(notifier_kind) })
  end

  # Stores the settings as the user's opt-outs: a row for each kind of email turned off.
  # @param user [User]
  def save!(user)
    opted_out_kinds = EmailOptOut::NOTIFIER_KINDS.reject { |notifier_kind| public_send(notifier_kind) }
    EmailOptOut.transaction do
      user.email_opt_outs.where.not(notifier_kind: opted_out_kinds).delete_all
      opted_out_kinds.each { |notifier_kind| user.email_opt_outs.find_or_create_by!(notifier_kind:) }
    end
  end
end
