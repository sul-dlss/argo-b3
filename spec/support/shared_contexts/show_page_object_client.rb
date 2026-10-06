# frozen_string_literal: true

# Stubs the DSA object client (Dor::Services::Client.object(druid)) with everything the object show page calls.
# When a new DSA client call is added to the show page, add it here so every spec that lands on the show page
# picks it up.
#
# Requires `druid`. Override the value lets (e.g., `version_inventory`, `milestones`, `release_tags`, `events`,
# `event_types`) or the `version_status` double for the data a spec cares about.
#
# Usage:
#   include_context 'with show page object client'
RSpec.shared_context 'with show page object client' do
  let(:object_lock) { 'lock1' }
  let(:version_inventory) { [] }
  let(:user_version_inventory) { [] }
  let(:milestones) { [] }
  let(:milestone_date) { false }
  let(:release_tags) { [] }
  let(:events) { [] }
  let(:event_types) { %w[version_open] }

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: version_client, milestones: milestones_client,
                                                   release_tags: release_tags_client,
                                                   user_version: user_version_client, events: events_client,
                                                   lock: object_lock)
  end
  let(:version_client) do
    instance_double(Dor::Services::Client::ObjectVersion, inventory: version_inventory, status: version_status)
  end
  let(:version_status) do
    instance_double(Dor::Services::Client::ObjectVersion::VersionStatus, accessioning?: false, closed?: false)
  end
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: user_version_inventory) }
  let(:milestones_client) do
    instance_double(Dor::Services::Client::Milestones, list: milestones, date: milestone_date)
  end
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: release_tags) }
  let(:events_client) { instance_double(Dor::Services::Client::Events) }
  let(:event_types_client) { instance_double(Dor::Services::Client::EventTypes, list: event_types) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Dor::Services::Client).to receive(:event_types).and_return(event_types_client)
    # Filters by event type when given, as DSA does.
    allow(events_client).to receive(:list) do |event_types:, **|
      event_types ? events.select { |event| event_types.include?(event.event_type) } : events
    end
  end
end
