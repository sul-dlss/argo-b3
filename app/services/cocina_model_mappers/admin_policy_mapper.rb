# frozen_string_literal: true

module CocinaModelMappers
  # Mapper for a Cocina AdminPolicy to the attributes for a CocinaModels::AdminPolicy.
  class AdminPolicyMapper
    def self.call(...)
      new(...).call
    end

    # @param cocina_object [Cocina::Models::AdminPolicyWithMetadata]
    def initialize(cocina_object:)
      @cocina_object = cocina_object
    end

    # @return [Hash] the mapped attributes
    def call # rubocop:disable Metrics/AbcSize
      {
        access_view: cocina_object.administrative.accessTemplate.view,
        access_download: cocina_object.administrative.accessTemplate.download,
        access_location: cocina_object.administrative.accessTemplate.location,
        use_and_reproduction_statement: cocina_object.administrative.accessTemplate.useAndReproductionStatement,
        license: cocina_object.administrative.accessTemplate.license,
        copyright: cocina_object.administrative.accessTemplate.copyright,
        admin_policy_druid: cocina_object.administrative.hasAdminPolicy,
        agreement_druid: cocina_object.administrative.hasAgreement
      }.compact
    end

    private

    attr_reader :cocina_object
  end
end
