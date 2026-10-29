# frozen_string_literal: true

# Methods for working with cocina objects
class CocinaSupport
  extend Dry::Monads[:result]

  # Validates a cocina model instance
  # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
  # @param [Hash] params the changed model parameters
  # @return [Dry::Monads::Success] if validation passes
  # @return [Dry::Monads::Failure] if validation fails
  def self.validate(cocina_object, **params)
    Cocina::Models.build(cocina_object.to_h.merge(**params))
    Success()
  rescue Cocina::Models::Error => e
    Failure(e.message)
  end

  # @param cocina_hash [Hash] a hash representing a Cocina model with metadata
  # @return [Cocina::Models::DROWithMetadata, Cocina::Models::CollectionWithMetadata, Cocina::Models::AdminPolicyWithMetadata]
  def self.build_from_cocina_hash(cocina_hash)
    created = cocina_hash.delete(:created)
    modified = cocina_hash.delete(:modified)
    lock = cocina_hash.delete(:lock)
    cocina_object = Cocina::Models.build(cocina_hash, validate: false)
    Cocina::Models.with_metadata(cocina_object, lock, created:, modified:)
  end

  # @param cocina_object [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy]
  # @return [Boolean] true if the object is an Agreement
  def self.agreement?(cocina_object)
    cocina_object.type == Cocina::Models::ObjectType.agreement
  end

  # A Virtual Object is identified by structure (its member orders reference other objects), not by type.
  # @param cocina_object [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy]
  # @return [Boolean] true if the object is a Virtual Object
  def self.virtual_object?(cocina_object)
    return false unless cocina_object.dro?

    Array(cocina_object.structural&.hasMemberOrders).any? { |member_order| member_order.members.present? }
  end

  # @param cocina_object [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy]
  # @return [Boolean] true if the object is an Item, i.e., a DRO that is not an Agreement or a Virtual Object
  def self.item?(cocina_object)
    cocina_object.dro? && !agreement?(cocina_object) && !virtual_object?(cocina_object)
  end

  # Items and Agreements have Content (see GLOSSARY), so their files are managed.
  # @param cocina_object [Cocina::Models::DRO, Cocina::Models::Collection, Cocina::Models::AdminPolicy]
  # @return [Boolean] true if the object is an Item or an Agreement
  def self.object_type_with_content?(cocina_object)
    item?(cocina_object) || agreement?(cocina_object)
  end
end
