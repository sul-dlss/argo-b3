# frozen_string_literal: true

# Presenter for a single Solr search result document.
class SolrDocPresenter < SearchResults::Item
  OBJECT_TYPES = {
    'item' => { label: 'Item', css_class: 'item' },
    'collection' => { label: 'Collection', css_class: 'collection' },
    'adminPolicy' => { label: 'APO', css_class: 'apo' },
    'agreement' => { label: 'Agreement', css_class: 'agreement' },
    'virtual object' => { label: 'Virtual object', css_class: 'virtual-object' }
  }.freeze

  def to_param
    druid
  end

  def object_type_label
    OBJECT_TYPES.fetch(object_type).fetch(:label)
  end

  def object_type_class
    OBJECT_TYPES.fetch(object_type).fetch(:css_class)
  end

  def collection?
    object_type == 'collection'
  end

  def admin_policy?
    object_type == 'adminPolicy'
  end

  def dro?
    !collection? && !admin_policy?
  end
end
