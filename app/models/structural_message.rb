class StructuralMessage < ApplicationRecord
  acts_as_message chat: :structural_chat

  scope :user_and_assistant, -> { where(role: %w[user assistant]) }

  private

  def extract_content
    return content_raw.to_json if has_attribute?(:content_raw) && content_raw.is_a?(Hash)

    super
  end
end
