class Model < ApplicationRecord
  acts_as_model chats: :structural_chats
end
