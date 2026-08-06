# frozen_string_literal: true

module CocinaModels
  # Base model for a Cocina object.
  class Base < Blanks::Base
    include ActiveModel::AttributeAssignment
    include NormalizationConcern

    alias update assign_attributes

    # @param cocina_object [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata]
    # @return [Base] a new instance built from the given Cocina object
    def self.build_from_cocina_object(cocina_object)
      new.tap { |instance| instance.send(:assign_from_cocina_object, cocina_object) }
    end

    attr_reader :external_identifier, :previous_cocina_object
    alias druid external_identifier

    attribute :description_hash, default: -> { { title: [{ value: ':auto' }] } }

    # All objects have an admin policy
    attribute :admin_policy_druid, :string
    validates :admin_policy_druid, presence: true

    # @param [String] description the description of the update for DSA Event
    # @param [String] user_name the sunetid of the user performing the action
    # @raise [Sdr::Repository::Error] if there is an error updating the object
    # @raise [ActiveModel::ValidationError] if the model is invalid
    def save!(user_name:, description: nil)
      raise 'Cannot save an object that has not been persisted; call #create! instead' unless persisted?
      return unless changed?

      validate!
      Sdr::Repository.update(cocina_object: mutated_cocina_object, user_name:, description:)
      changes_applied
    end

    # @param [String] user_name the sunetid of the user performing the action
    # @param [Boolean] accession whether to accession the object after registering it
    # @raise [RuntimeError] if the object has already been persisted
    # @raise [Sdr::Repository::Error] if there is an error registering the object
    # @raise [ActiveModel::ValidationError] if the model is invalid
    def create!(user_name:, accession: false)
      raise 'Cannot create an object that has already been persisted; call #save! instead' if persisted?

      validate!
      registered_cocina_object = Sdr::Repository.register(request_cocina_object:, user_name:)
      Sdr::Repository.accession(druid: registered_cocina_object.externalIdentifier, user_name:) if accession
      assign_from_cocina_object(registered_cocina_object)
    end

    def to_param
      persisted? ? druid : nil
    end

    def to_key
      persisted? ? [druid] : nil
    end

    def persisted?
      previous_cocina_object.present?
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

    def changed?
      # This allows subclasses to track changes on associated objects (e.g., CatalogLinks).
      super || tracked_associations_changed?
    end

    # Subclasses can override this.
    def tracked_associations_changed?
      false
    end

    private

    def assign_from_cocina_object(cocina_object)
      @external_identifier = cocina_object.externalIdentifier
      @previous_cocina_object = cocina_object
      assign_attributes(model_attrs_for(cocina_object))
      changes_applied
    end

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

    # @return [Cocina::Models::RequestDRO, Cocina::Models::RequestCollection, Cocina::Models::RequestAdminPolicy]
    #   the new request Cocina object based on the model attributes, to be implemented by subclasses
    def request_cocina_object
      raise NotImplementedError,
            'Subclasses must implement #request_cocina_object to return a new request Cocina object ' \
            'based on the model attributes'
    end
  end
end
