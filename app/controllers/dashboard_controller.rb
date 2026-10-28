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

  RECENT_OBJECT_FIELDS = [
    Search::Fields::ID,
    Search::Fields::TITLE,
    Search::Fields::OBJECT_TYPES,
    Search::Fields::ALL_TAGS
  ].freeze

  RECENT_MULTI_ITEM_DEPOSITS_LIMIT = 5
  RECENT_DRAFTS_AND_DEPOSITS_LIMIT = 5

  def index
    @go_to_druid_form = GoToDruidForm.new
    set_recent_object_docs
    set_recent_multi_item_deposit_actions
    set_recent_drafts_and_deposits
    set_pinned_object_docs
    set_pinned_searches
    set_pinned_tags
  end

  def go_to_druid
    @go_to_druid_form = GoToDruidForm.new(GoToDruidForm.params_from(params))

    if @go_to_druid_form.valid?
      redirect_to object_path(@go_to_druid_form.druid)
    else
      set_recent_object_docs
      set_recent_multi_item_deposit_actions
      set_recent_drafts_and_deposits
      set_pinned_object_docs
      set_pinned_searches
      set_pinned_tags
      render :index, status: :unprocessable_content
    end
  end

  private

  def set_recent_object_docs
    recent_object_druids = Array(session[:recent_object_druids])
    @recent_object_docs = if recent_object_druids.present?
                            recent_object_docs = Searchers::ItemByDruid.call(
                              druids: recent_object_druids,
                              fields: RECENT_OBJECT_FIELDS,
                              user_scope: current_user_scope
                            )
                            docs_by_druid = recent_object_docs.index_by(&:druid)
                            recent_object_druids.filter_map { |druid| docs_by_druid[druid] }
                          else
                            []
                          end
  end

  def set_recent_multi_item_deposit_actions
    @recent_multi_item_deposit_actions = MultiItemDepositAction.where(user: current_user)
                                                               .order(updated_at: :desc, id: :desc)
                                                               .limit(RECENT_MULTI_ITEM_DEPOSITS_LIMIT)
  end

  def set_recent_drafts_and_deposits
    @recent_drafts_and_deposits_search_form = ResultsSearchForm.new(last_updated_by: [current_user.sunetid],
                                                                    object_types: ['item'],
                                                                    sort: 'last_updated_date_desc')
    @recent_draft_and_deposit_docs = Searchers::Item.call(search_form: @recent_drafts_and_deposits_search_form,
                                                          user_scope: current_user_scope,
                                                          per_page: RECENT_DRAFTS_AND_DEPOSITS_LIMIT)
                                                    .map { |result| SolrDocPresenter.new(solr_doc: result.solr_doc) }
    @recent_draft_and_deposit_statuses = statuses_for(@recent_draft_and_deposit_docs)
  end

  # @return [Hash<String, Symbol>] the ObjectStatusPresenter#status of each doc, keyed by druid
  def statuses_for(docs)
    druids = docs.map(&:druid)
    return {} if druids.empty?

    version_statuses = Sdr::VersionService.statuses(druids:)
    contents = Content.latest_staging_activities(druids:)
    docs.to_h do |doc|
      version_service = Sdr::VersionService.new(druid: doc.druid, status: version_statuses[doc.druid])
      [doc.druid, ObjectStatusPresenter.new(document: doc, version_service:, content: contents[doc.druid]).status]
    end
  end

  def set_pinned_searches
    @pinned_searches = PinnedSearch.where(user: current_user)
  end

  def set_pinned_tags
    @pinned_tags = PinnedTag.where(user: current_user)
  end

  def set_pinned_object_docs
    pinned_object_druids = PinnedObject.where(user: current_user).pluck(:druid)
    grouped_pinned_object_docs = if pinned_object_druids.present?
                                   pinned_object_docs = Searchers::ItemByDruid.call(druids: pinned_object_druids,
                                                                                    fields: PINNED_OBJECT_FIELDS,
                                                                                    user_scope: current_user_scope)
                                   pinned_object_docs.group_by(&:object_type)
                                 else
                                   {}
                                 end
    @pinned_item_docs = grouped_pinned_object_docs.fetch('item', [])
    @pinned_collection_docs = grouped_pinned_object_docs.fetch('collection', [])
    @pinned_apo_docs = grouped_pinned_object_docs.fetch('APO', [])
    @pinned_virtual_object_docs = grouped_pinned_object_docs.fetch('virtual object', [])
  end
end
