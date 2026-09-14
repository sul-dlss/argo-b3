# frozen_string_literal: true

# Form object for a ticket tag on an item
class TicketTagForm < ApplicationForm
  TICKET_TAG_PREFIX = 'Ticket : '

  attribute :tag, :string
  # Tolerate a pasted tag that includes prefix.
  normalizes :tag, with: ->(value) { value.strip.delete_prefix(TICKET_TAG_PREFIX).strip.presence }
end
