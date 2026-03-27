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

    attribute :source_id, :string
    validates :source_id, presence: true
    validates :source_id, format: { with: /\A.+:.+\z/ }

    # Access fields
    attribute :use_and_reproduction_statement, :string
    attribute :license, :string
    attribute :copyright, :string

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
