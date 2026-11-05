# frozen_string_literal: true

# Controller for managing the administrative tags of an object
class AdministrativeTagsController < ApplicationController
  before_action :set_druid_title_and_cocina_object

  def edit
    authorize! @cocina_object, to: :tag?, with: ObjectPolicy

    @administrative_tags_form = AdministrativeTagsForm.from_tags(current_tags)
  end

  def update
    authorize! @cocina_object, to: :tag?, with: ObjectPolicy

    @administrative_tags_form = AdministrativeTagsForm.new(AdministrativeTagsForm.params_from(params))
    return render :edit, status: :unprocessable_content unless @administrative_tags_form.valid?

    if @administrative_tags_form.tags_changed?(current_tags)
      save_tags
      flash[:toast] = t('edit.administrative_tags.toasts.updated')
    end
    redirect_to object_path(@druid)
  rescue Sdr::AdministrativeTags::Error
    render_save_failed
  end

  private

  def save_tags
    @administrative_tags_form.save!(druid: @druid)
    # The show page's cached solr doc is keyed on the lock, which tag changes do not change.
    Rails.cache.delete(CacheSupport.solr_doc_cache_key(druid: @druid))
  end

  def render_save_failed
    flash.now[:danger] = t('edit.administrative_tags.errors.save_failed')
    render :edit, status: :unprocessable_content
  end

  def current_tags
    @current_tags ||= Sdr::AdministrativeTags.list(druid: @druid)
  end

  def set_druid_title_and_cocina_object
    @druid = params[:druid]
    @cocina_object = Sdr::Repository.find(druid: @druid, without_structural_contains: true)
    @title = CocinaSupport.title(@cocina_object)
  end
end
