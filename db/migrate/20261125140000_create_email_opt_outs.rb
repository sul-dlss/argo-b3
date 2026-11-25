# frozen_string_literal: true

class CreateEmailOptOuts < ActiveRecord::Migration[8.1]
  def change
    # A user's opt-out of one kind of Notification email; no row means the email is on.
    create_table :email_opt_outs do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :notifier_kind, null: false
      t.timestamps
    end
    add_index :email_opt_outs, %i[user_id notifier_kind], unique: true
  end
end
