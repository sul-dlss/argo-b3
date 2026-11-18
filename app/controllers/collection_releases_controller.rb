# frozen_string_literal: true

# Controller for managing the release of a collection
class CollectionReleasesController < ApplicationController
  before_action :set_druid_and_cocina_object

  def new
    authorize! @cocina_object, to: :release?, with: ObjectPolicy
    return redirect_dark if CocinaSupport.dark?(@cocina_object)

    @collection_release_tags_form = CollectionReleaseTagsForm.from_release_tags(collection_release_tags)
  end

  def create
    authorize! @cocina_object, to: :release?, with: ObjectPolicy
    return redirect_dark if CocinaSupport.dark?(@cocina_object)

    @collection_release_tags_form = CollectionReleaseTagsForm.new(collection_release_tags_form_params)
    release_targets = @collection_release_tags_form.save!(druid: @druid, user_name: current_user.sunetid,
                                                          release_tags: collection_release_tags)
    flash[:toast] = t('edit.releases.toasts.updated') if release_targets.any?
    redirect_to object_path(@druid)
  rescue Sdr::Repository::Error
    render_save_failed
  end

  private

  def collection_release_tags
    @collection_release_tags ||= Sdr::Repository.release_tags(druid: @druid, public: false)
  end

  def collection_release_tags_form_params
    CollectionReleaseTagsForm.params_from(params)
  end

  def render_save_failed
    flash.now[:danger] = t('edit.releases.errors.save_failed')
    render :new, status: :unprocessable_content
  end

  def set_druid_and_cocina_object
    @druid = params[:druid]
    @cocina_object = Sdr::Repository.find(druid: @druid)
    @title = CocinaSupport.title(@cocina_object)
  end

  def redirect_dark
    flash[:danger] = t('edit.releases.errors.dark')
    redirect_to object_path(@druid)
  end
end
