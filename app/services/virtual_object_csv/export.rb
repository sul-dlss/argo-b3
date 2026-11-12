# frozen_string_literal: true

module VirtualObjectCsv
  # Serializes a virtual object as a row of the create virtual object bulk action's CSV (no header row).
  class Export
    # @param cocina_object [Cocina::Models::DRO] the virtual object
    # @return [String] the virtual object's bare druid followed by its constituents' bare druids, in order
    def self.as_csv(cocina_object:)
      druids = [cocina_object.externalIdentifier, *CocinaSupport.constituent_druids(cocina_object)]
      CSV.generate_line(druids.map { |druid| DruidSupport.bare_druid_from(druid) })
    end
  end
end
