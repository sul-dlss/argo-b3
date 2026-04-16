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
    object_type == 'admin_policy'
  end

  def dro?
    !collection? && !admin_policy?
  end
end
