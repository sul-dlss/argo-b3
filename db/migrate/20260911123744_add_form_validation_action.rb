# frozen_string_literal: true

# Creates form validation actions for tracking asynchronous form validations.
class AddFormValidationAction < ActiveRecord::Migration[8.1]
  def change
    create_table :form_validation_actions do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :form_payload, null: false
      t.jsonb :error_data
      t.string :status, null: false, default: 'created'

      t.timestamps
    end
  end
end
