# frozen_string_literal: true

# Controller for objects (DRO, collection, admin policy)
class ObjectsController < ApplicationController
  def show
    @solr_doc = SolrDocPresenter.new(solr_doc: Sdr::Repository.find_solr(druid: params[:druid]))
    authorize! @solr_doc, with: ObjectPolicy

    set_from_last_search_cookie # This provides @last_search_form

    case @solr_doc.object_type
    when 'collection'
      render :show_collection
    when 'admin_policy'
      render :show_admin_policy
    else
      # This also includes agreements and virtual objects.
      render :show_dro
    end
  end

  def show_json
    @cocina_object = Sdr::Repository.find(druid: params[:druid])

    authorize! @cocina_object, with: ObjectPolicy

    render layout: false
  end
end
