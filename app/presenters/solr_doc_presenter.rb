# frozen_string_literal: true

# Presenter for a single Solr search result document.
class SolrDocPresenter < SearchResults::Item
  # Keyed by the object type values indexed in Solr. i18n_key is used to look up object_types.<i18n_key>.label.
  OBJECT_TYPES = {
    'item' => { i18n_key: 'item', css_class: 'object-type-item' },
    'collection' => { i18n_key: 'collection', css_class: 'object-type-collection' },
    'APO' => { i18n_key: 'apo', css_class: 'object-type-apo' },
    'agreement' => { i18n_key: 'agreement', css_class: 'object-type-agreement' },
    'virtual object' => { i18n_key: 'virtual_object', css_class: 'object-type-virtual-object' }
  }.freeze

  def to_param
    druid
  end

  def object_type_label
    I18n.t("object_types.#{OBJECT_TYPES.fetch(object_type).fetch(:i18n_key)}.label")
  end

  def object_type_class
    OBJECT_TYPES.fetch(object_type).fetch(:css_class)
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

  def dro?
    !collection? && !admin_policy? && !agreement?
  end

  # items with a purl page/description overviews
  def dro_or_collection?
    dro? || collection?
  end
end
