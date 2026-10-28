# frozen_string_literal: true

# Controller for collection select options, e.g., for a Tom Select field that loads options as the user types.
class CollectionOptionsController < ApplicationController
  # The options are restricted to the collections the user can see (or, when editable, edit).
  skip_verify_authorized

  def index
    render json: collections.map { |title, druid| { value: druid, text: title } }
  end

  private

  def collections
    query = params.require(:q).strip
    if druid_query?(query)
      Searchers::CollectionListByDruid.call(druids: [DruidSupport.prefixed_druid_from(query)],
                                            user_scope: current_user_scope, apo_druid: limit_apo_druid, editable:)
    else
      Searchers::CollectionList.call(query:, user_scope: current_user_scope, apo_druid: limit_apo_druid, editable:)
    end
  end

  # Whether to limit to the collections the user can edit, e.g., when registering an item.
  def editable
    ActiveModel::Type::Boolean.new.cast(params[:editable]) || false
  end

  # The APO to limit the collections to, if limiting by APO and an APO is selected.
  def limit_apo_druid
    params[:apo_druid].presence if ActiveModel::Type::Boolean.new.cast(params[:limit_by_apo])
  end

  # A bare or prefixed druid?
  def druid_query?(query)
    DruidTools::Druid.valid?(query, true)
  end
end
