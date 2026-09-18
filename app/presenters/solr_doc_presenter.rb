# frozen_string_literal: true

# Presenter for a single Solr search result document.
class SolrDocPresenter < SearchResults::Item
  def to_param
    druid
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
