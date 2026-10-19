# frozen_string_literal: true

# Builds an Sdr::VersionService double with every status method stubbed, so adding a method to the service doesn't
# break specs that don't care about it. Defaults are an open first version that can be closed; override as needed.
module VersionServiceDouble
  DEFAULTS = { open?: true, openable?: false, closeable?: true, assembling?: false, accessioning?: false,
               closed?: false, version: 1, version_description: 'Initial version', update_description: nil }.freeze

  def version_service_double(**overrides)
    status = DEFAULTS.merge(overrides)
    derived = { editable?: status[:openable?] || status[:closeable?],
                open_and_not_assembling?: status[:open?] && !status[:assembling?] }
    instance_double(Sdr::VersionService, **derived, **status)
  end
end

RSpec.configure do |config|
  config.include VersionServiceDouble
end
