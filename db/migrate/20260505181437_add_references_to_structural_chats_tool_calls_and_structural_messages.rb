class AddReferencesToStructuralChatsToolCallsAndStructuralMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :structural_chats, :model, foreign_key: true
    add_reference :tool_calls, :structural_message, null: false, foreign_key: true
    add_reference :structural_messages, :structural_chat, null: false, foreign_key: true
    add_reference :structural_messages, :model, foreign_key: true
    add_reference :structural_messages, :tool_call, foreign_key: true
  end
end
