# frozen_string_literal: true

# Controller for the dashboard (root page)
class DashboardController < ApplicationController
  skip_verify_authorized only: %i[index go_to_druid]

  # Fields needed to render the pinned items, collections, and APOs tables.
  PINNED_OBJECT_FIELDS = [
    Search::Fields::ID,
    Search::Fields::TITLE,
    Search::Fields::OBJECT_TYPES,
    Search::Fields::COLLECTION_DRUIDS,
    Search::Fields::COLLECTION_TITLES,
    Search::Fields::APO_DRUID,
    Search::Fields::APO_TITLE,
    Search::Fields::AGREEMENT_DRUID,
    Search::Fields::AGREEMENT_TITLE,
    Search::Fields::CONSTITUENTS_COUNT
  ].freeze

  def index
    @go_to_druid_form = GoToDruidForm.new
    set_pinned_object_docs
  end

  def go_to_druid
    @go_to_druid_form = GoToDruidForm.new(params.expect(go_to_druid: [:druid]))

    if @go_to_druid_form.valid?
      redirect_to object_path(@go_to_druid_form.druid)
    else
      set_pinned_object_docs
      render :index, status: :unprocessable_content
    end
  end

  private

  def set_pinned_object_docs
    pinned_object_druids = PinnedObject.where(user: current_user).pluck(:druid)
    grouped_pinned_object_docs = if pinned_object_druids.present?
                                   pinned_object_docs = Searchers::ItemByDruid.call(druids: pinned_object_druids,
                                                                                    fields: PINNED_OBJECT_FIELDS)
                                   pinned_object_docs.group_by(&:object_type)
                                 else
                                   {}
                                 end
    @pinned_item_docs = grouped_pinned_object_docs.fetch('item', [])
    @pinned_collection_docs = grouped_pinned_object_docs.fetch('collection', [])
    @pinned_apo_docs = grouped_pinned_object_docs.fetch('adminPolicy', [])
    @pinned_virtual_object_docs = grouped_pinned_object_docs.fetch('virtual object', [])
  end
end
