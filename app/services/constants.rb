# frozen_string_literal: true

# A module for including constants throughout the Argo application
module Constants
  RELEASE_TARGETS = [
    %w[Searchworks Searchworks],
    %w[Earthworks Earthworks],
    ['Search engines', 'PURL sitemap']
  ].freeze

  WORKFLOWS = %w[
    accessionWF
    gisAssemblyWF
    gisDeliveryWF
    goobiWF
    registrationWF
    wasSeedPreassemblyWF
  ].freeze
end
