# frozen_string_literal: true

# Controller for managing the release of an item
class ItemReleasesController < ApplicationController
  before_action :set_druid_and_cocina_object

  def new
    authorize! @cocina_object, to: :release?, with: ObjectPolicy
    return redirect_dark if CocinaSupport.dark?(@cocina_object)

    @item_release_tags_form = ItemReleaseTagsForm.from_release_tags(item_release_tags)
    set_follow_collection_disabled_fields
  end

  def create
    authorize! @cocina_object, to: :release?, with: ObjectPolicy
    return redirect_dark if CocinaSupport.dark?(@cocina_object)

    @item_release_tags_form = ItemReleaseTagsForm.new(item_release_tags_form_params)
    release_targets = @item_release_tags_form.save!(druid: @druid, user_name: current_user.sunetid,
                                                    release_tags: item_release_tags)
    flash[:toast] = t('edit.item_releases.toasts.updated') if release_targets.any?
    redirect_to object_path(@druid)
  rescue Sdr::Repository::Error
    render_save_failed
  end

  private

  def item_release_tags
    @item_release_tags ||= Sdr::Repository.release_tags(druid: @druid, public: false)
  end

  # Targets with an item tag can no longer follow the collection.
  def set_follow_collection_disabled_fields
    @follow_collection_disabled_fields = ItemReleaseTagsForm.tagged_choices(item_release_tags).keys
  end

  def item_release_tags_form_params
    ItemReleaseTagsForm.params_from(params)
  end

  def render_save_failed
    flash.now[:danger] = t('edit.item_releases.errors.save_failed')
    set_follow_collection_disabled_fields
    render :new, status: :unprocessable_content
  end

  def set_druid_and_cocina_object
    @druid = params[:druid]
    @cocina_object = Sdr::Repository.find(druid: @druid, without_structural_contains: true)
    @title = CocinaSupport.title(@cocina_object)
  end

  def redirect_dark
    flash[:danger] = t('edit.item_releases.errors.dark')
    redirect_to object_path(@druid)
  end
end
