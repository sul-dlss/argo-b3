class AddPerformSpeechToText < ActiveRecord::Migration[8.1]
  def change
    add_column :contents, :perform_speech_to_text, :boolean, null: false, default: false
    add_column :multi_item_deposit_actions, :perform_speech_to_text, :boolean, null: false, default: false
  end
end
