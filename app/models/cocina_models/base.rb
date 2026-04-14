# frozen_string_literal: true

module CocinaModels
  # Base model for a Cocina object.
  class Base
    include ActiveModel::Model
    include ActiveModel::Dirty
    include ActiveModel::Attributes

    alias update assign_attributes

    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata]
    def initialize(cocina_object)
      @external_identifier = cocina_object.externalIdentifier
      @previous_cocina_object = cocina_object
      super(**model_attrs_for(cocina_object))
      changes_applied
    end

    attr_reader :external_identifier, :previous_cocina_object
    alias druid external_identifier

    # @param [String] description the description of the update for DSA Event
    # @param [String] user_name the sunetid of the user performing the action
    # @raise [Sdr::Repository::Error] if there is an error updating the object
    # @raise [ActiveModel::ValidationError] if the model is invalid
    def save!(user_name:, description: nil)
      return unless changed?

      validate!
      Sdr::Repository.update(cocina_object: mutated_cocina_object, user_name:, description:)
      changes_applied
    end

    def to_param
      persisted? ? druid : nil
    end

    def to_key
      persisted? ? [druid] : nil
    end

    def persisted?
      true
    end

    def dro?
      is_a?(Dro)
    end

    def collection?
      is_a?(Collection)
    end

    def admin_policy?
      is_a?(AdminPolicy)
    end

    private

    # @return [Hash] the attributes for initializing the model, to be implemented by subclasses
    def model_attrs_for(cocina_object)
      raise NotImplementedError,
            'Subclasses must implement #model_attrs_for to return a hash of attributes for the model'
    end

    # @return [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata] the new Cocina object based
    #   on the model attributes, to be implemented by subclasses
    def mutated_cocina_object
      raise NotImplementedError, 'Subclasses must implement #mutated_cocina_object to return a new Cocina object ' \
                                 'based on the model attributes'
    end
  end
end
