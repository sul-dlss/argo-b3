# frozen_string_literal: true

module CocinaObjectMutators
  # Mapper for merging a CocinaModels::AdminPolicy with an existing Cocina::Models::AdminPolicyWithMetadata.
  # Not a BaseMutator, since an APO has no identification or access, and its object defaults are in the
  # administrative access template.
  class AdminPolicyMutator
    def self.call(...)
      new(...).call
    end

    # @param cocina_object [Cocina::Models::AdminPolicyWithMetadata]
    # @param cocina_model [CocinaModels::AdminPolicy]
    def initialize(cocina_object:, cocina_model:)
      @cocina_object = cocina_object
      @cocina_model = cocina_model
    end

    # @return [Cocina::Models::AdminPolicyWithMetadata]
    def call
      Cocina::Models.with_metadata(Cocina::Models.build(build_new_cocina_props), cocina_object.lock)
    end

    private

    attr_reader :cocina_object, :cocina_model

    # @return [Hash] the props of the cocina object, updated from the cocina model
    def build_new_cocina_props
      Cocina::Models.without_metadata(cocina_object).to_h.tap do |new_cocina_props|
        new_cocina_props[:description] = build_description
        update_administrative(new_cocina_props[:administrative])
      end
    end

    def build_description
      cocina_model.description_hash.merge(purl: Cocina::Models::Mapping::Purl.for(druid: cocina_model.druid))
    end

    # Other administrative metadata (e.g., registration workflows and collections) is retained.
    def update_administrative(administrative_hash)
      administrative_hash[:hasAdminPolicy] = cocina_model.apo_druid
      administrative_hash[:hasAgreement] = cocina_model.agreement_druid
      administrative_hash[:accessTemplate] =
        administrative_hash.fetch(:accessTemplate, {}).merge(access_template_from_model).compact
    end

    # Blank values (e.g., from form fields left empty) are removed by the caller.
    def access_template_from_model
      {
        view: cocina_model.access_view,
        download: cocina_model.access_download,
        location: cocina_model.access_location,
        copyright: cocina_model.copyright.presence,
        license: cocina_model.license.presence,
        useAndReproductionStatement: cocina_model.use_and_reproduction_statement.presence
      }
    end
  end
end
