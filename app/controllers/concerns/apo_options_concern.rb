# frozen_string_literal: true

# Concern for controllers whose forms select a governing APO.
module ApoOptionsConcern
  extend ActiveSupport::Concern

  private

  # The APOs the user can edit, plus an existing object's current APO (even if the user cannot edit it),
  # so that saving an edit does not change it.
  # @param current_apo_druid [String, nil]
  # @return [Array<Array(String, String)>] title and druid pairs
  def apo_options(current_apo_druid:)
    options = Searchers::AdminPolicyList.call(user_scope: current_user_scope, editable: true)
    return options if current_apo_druid.blank? || options.any? { |_title, druid| druid == current_apo_druid }

    [[Searchers::TitlesByDruid.call(druids: [current_apo_druid])[current_apo_druid], current_apo_druid]] + options
  end
end
