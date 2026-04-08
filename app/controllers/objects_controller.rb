# frozen_string_literal: true

# Controller for objects (DRO, collection, admin policy)
class ObjectsController < ApplicationController
  def show
    @cocina_model = CocinaModels::PresenterFactory.find_and_build(params[:druid], structural: false)

    authorize! @cocina_model.cocina_object, with: ObjectPolicy

    if @cocina_model.collection?
      render :show_collection
    elsif @cocina_model.admin_policy?
      render :show_admin_policy
    else
      render :show_dro
    end
  end

  def show_json
    @cocina_model = CocinaModels::PresenterFactory.find_and_build(params[:druid])

    authorize! @cocina_model.cocina_object, with: ObjectPolicy

    render layout: false
  end
end
