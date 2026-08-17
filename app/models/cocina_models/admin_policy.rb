# frozen_string_literal: true

module CocinaModels
  # Model for a Cocina AdminPolicy object.
  class AdminPolicy < Base
    include AccessConcern

    # @param cocina_object [Cocina::Models::AdminPolicyWithMetadata] the Cocina object to build this model from
    def self.build_from_cocina_object(cocina_object)
      unless cocina_object.is_a?(Cocina::Models::AdminPolicyWithMetadata)
        raise ArgumentError, 'Expected a Cocina::Models::AdminPolicyWithMetadata'
      end

      super
    end

    attribute :agreement_druid, :string
    validates :agreement_druid, presence: true

    private

    def model_attrs_for(cocina_object)
      CocinaModelMappers::AdminPolicyMapper.call(cocina_object:)
    end

    def request_cocina_object
      Cocina::Models.build_request(
        {
          type: Cocina::Models::ObjectType.admin_policy,
          administrative: {
            hasAdminPolicy: admin_policy_druid,
            hasAgreement: agreement_druid,
            accessTemplate: {
              view: access_view,
              download: access_download,
              location: access_location,
              copyright:,
              license:,
              useAndReproductionStatement: use_and_reproduction_statement
            }
          },
          description: description_hash,
          version: 1
        }
      )
    end
  end
end
