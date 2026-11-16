# frozen_string_literal: true

class AddStructuringStateToContents < ActiveRecord::Migration[8.1]
  def change
    add_column :contents, :structuring_state, :string, null: false, default: 'structuring_not_in_progress'
  end
end
