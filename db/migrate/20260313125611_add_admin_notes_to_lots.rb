class AddAdminNotesToLots < ActiveRecord::Migration[8.1]
  def change
    add_column :lots, :admin_notes, :text
  end
end
