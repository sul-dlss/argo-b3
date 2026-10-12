# frozen_string_literal: true

# Presenter for a single Solr search result document.
class SolrDocPresenter < SearchResults::Item
  def to_param
    druid
  end

  def object_type_label
    return object_type if object_type == 'APO'

    object_type.capitalize
  end

  def object_type_class
    "object-type-#{object_type.parameterize}"
  end

  def collection?
    object_type == 'collection'
  end

  def admin_policy?
    object_type == 'APO'
  end

  def agreement?
    object_type == 'agreement'
  end

  def virtual_object?
    object_type == 'virtual object'
  end

  def item?
    object_type == 'item'
  end

  # @param object_types [Array<String>] object types to match, e.g., 'item', 'virtual object', 'collection',
  #   'APO', 'agreement'
  # @return [Boolean] true if the object type is any of the provided object types
  def object_type?(*object_types)
    object_types.include?(object_type)
  end

  def releasable_type?
    object_type?('item', 'virtual object', 'collection')
  end

  def publishable_type?
    object_type?('item', 'virtual object', 'collection', 'agreement')
  end
end
