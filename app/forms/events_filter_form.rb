# frozen_string_literal: true

# Form object for filtering the events shown for an object.
class EventsFilterForm < ApplicationForm
  # Event types that are selected when the events are not filtered.
  DEFAULT_EVENT_TYPES = %w[
    accession_request
    cleanup-workspace
    collection_changed
    delete
    embargo_released
    publish_request_received
    publishing_complete
    registration
    shelving_complete
    update
    user_version_created
    user_version_moved
    user_version_permanently_withdrawn
    user_version_withdrawn
    version_close
    version_description_update
    version_discard
    version_open
    druid_version_replicated
    preservation_audit_failure
    preservation_audit_success
    ocr_errored
    ocr_success
  ].freeze

  # from and to are the values of datetime-local inputs (e.g., "2026-10-06T10:00"), in Pacific time.
  attribute :from, :string
  attribute :to, :string
  attribute :event_types, array: true, default: []

  # @param available_event_types [Array<String>] the valid event types
  # @return [EventsFilterForm] a form with the default event types (that are valid event types) selected
  def self.with_defaults(available_event_types:)
    new(event_types: DEFAULT_EVENT_TYPES & available_event_types)
  end

  # The hidden field for the event types select submits a blank value, so that deselecting all
  # event types can be distinguished from the default event types.
  # @return [Array<String>] the selected event types
  def selected_event_types
    event_types.compact_blank
  end

  def event_types_selected?
    selected_event_types.present?
  end

  # @param available_event_types [Array<String>] the valid event types
  # @return [Array<String>,nil] the event types to filter by, or nil when all event types are selected
  def event_types_filter(available_event_types:)
    return if (available_event_types - selected_event_types).empty?

    selected_event_types
  end

  # @return [ActiveSupport::TimeWithZone,nil] only events created at or after this time (inclusive)
  def from_time
    parse_time(from)
  end

  # @return [ActiveSupport::TimeWithZone,nil] only events created before this time (exclusive)
  def to_time
    parse_time(to)
  end

  private

  def parse_time(value)
    return if value.blank?

    Time.find_zone(Constants::TIME_ZONE).parse(value)
  rescue ArgumentError
    nil
  end
end
