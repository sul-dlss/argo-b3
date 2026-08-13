# frozen_string_literal: true

# Controller for managing content (structural)
class ContentsController < ApplicationController
  def edit
    cocina_object = Sdr::Repository.find(druid:)
    authorize! cocina_object, with: ItemPolicy

    @content = find_or_create_content(cocina_object:)
    @solr_doc = Sdr::Repository.find_solr(druid:)

    @solr_doc = fetch_solr_doc
  end

  def update; end

  private

  def druid
    params[:druid]
  end

  def find_or_create_content(cocina_object:)
    Content.find_by(druid: cocina_object.externalIdentifier, lock: cocina_object.lock) ||
      Contents::Builder.call(cocina_object:)
  end

  def fetch_solr_doc
    solr_doc = Sdr::Repository.find_solr(druid: params[:druid])
    SolrDocPresenter.new(solr_doc:)
  end
end
