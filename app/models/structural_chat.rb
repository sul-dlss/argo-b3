class StructuralChat < ApplicationRecord
  acts_as_chat messages: :structural_messages
  alias messages structural_messages

  belongs_to :user
end
