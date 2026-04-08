# frozen_string_literal: true

module CocinaModels
  # Factory for creating Cocina model presenter from from Cocina models.
  class PresenterFactory
    # @param cocina_model [CocinaModels::Dro, CocinaModels::Collection]
    # @return [CocinaModels::DroPresenter, CocinaModels::CollectionPresenter] the created model presenter
    # @raise [ArgumentError] if the cocina_model is not a DRO or Collection model
    def self.build(cocina_model)
      case cocina_model
      when CocinaModels::Dro
        DroPresenter.new(cocina_model)
      when CocinaModels::Collection
        CollectionPresenter.new(cocina_model)
      when CocinaModels::AdminPolicy
        AdminPolicyPresenter.new(cocina_model)
      else
        raise ArgumentError, 'Expected a CocinaModels::Dro, CocinaModels::Collection, or CocinaModels::AdminPolicy'
      end
    end

    def self.find_and_build(druid, structural: true)
      cocina_object = if structural
                        Sdr::Repository.find(druid:)
                      else
                        find_lite(druid)
                      end
      CocinaModels::Factory.build(cocina_object)
                           .then { |model| build(model) }
    end

    def self.find_lite(druid)
      # Sdr::Repository.find_lite retrieves a cocina object without structural
      # because the structural can be quite large and slow to retrieve.
      # However, collections are recorded in the structural.
      # The collection druids are retrieved from the Solr doc and added to the cocina object.
      # This violates the design principle of only using DSA (not Solr) to render show pages
      # but it is what is is.
      cocina_object = Sdr::Repository.find_lite(druid:, structural: false)
      return cocina_object unless cocina_object.is_a?(Cocina::Models::DROLite)

      collection_druids = Searchers::SingleItemByDruid.call(druid:, fields: Search::Fields::COLLECTION_DRUIDS).collection_druids
      cocina_object.new(structural: { isMemberOf: Array(collection_druids) })
    end
    private_class_method :find_lite
  end
end
