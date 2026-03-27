# frozen_string_literal: true

module Cocina
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
      super(source_id: cocina_object.identification.sourceId)
      changes_applied
    end

    attr_reader :external_identifier, :previous_cocina_object

    attribute :source_id, :string
    validates :source_id, presence: true
    validates :source_id, format: { with: /\A.+:.+\z/ }

    # @param [String] description the description of the update for DSA Event
    # @param [String] user_name the sunetid of the user performing the action
    # @raise [Sdr::Repository::Error] if there is an error updating the object
    # @raise [ActiveModel::ValidationError] if the model is invalid
    def save!(user_name:, description: nil)
      return unless changed?

      validate!
      new_cocina_props = Cocina::Models.without_metadata(previous_cocina_object).to_h

      new_cocina_props[:identification][:sourceId] = source_id

      new_cocina_object = Cocina::Models.with_metadata(Cocina::Models.build(new_cocina_props),
                                                       previous_cocina_object.lock)
      Sdr::Repository.update(cocina_object: new_cocina_object,
                             user_name:, description:)
      changes_applied
    end
  end
end
