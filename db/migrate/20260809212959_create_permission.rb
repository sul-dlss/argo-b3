class CreatePermission < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions do |t|
      t.string :workgroup, null: false
      t.string :permission_type, null: false
      t.string :target_druid
      t.timestamps

      t.index [:workgroup, :permission_type, :target_druid], unique: true, nulls_not_distinct: true
      t.index :target_druid
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          INSERT INTO permissions (workgroup, permission_type, created_at, updated_at)
          VALUES ('sdr:argo_administrators', 'admin', NOW(), NOW())
        SQL
      end
    end
  end
end
