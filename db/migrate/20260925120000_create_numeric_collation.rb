# frozen_string_literal: true

# ICU collation that orders embedded digits numerically (e.g., image2 before image10).
class CreateNumericCollation < ActiveRecord::Migration[8.1]
  def up
    execute "CREATE COLLATION numeric (provider = icu, locale = 'en-u-kn')"
  end

  def down
    execute 'DROP COLLATION numeric'
  end
end
