# frozen_string_literal: true

# Concern for register forms, whose Cancel returns to the referring page.
module RegisterCancelConcern
  extend ActiveSupport::Concern

  private

  # @return [String] the referer, or the dashboard when the referer is a register form (which would loop back here)
  def register_cancel_path
    referer_path = URI.parse(request.referer.to_s).path
    return root_path if referer_path.blank? || register_form_paths.include?(referer_path)

    request.referer
  rescue URI::InvalidURIError
    root_path
  end

  # Includes the create paths, which re-render the form when it is invalid.
  def register_form_paths
    [new_item_path, items_path, new_collection_path, collections_path, new_agreement_path, agreements_path,
     new_apo_path, apos_path, new_multiple_item_path, multiple_items_path]
  end
end
