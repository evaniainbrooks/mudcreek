class AddMemberBirthdaysToKiosks < ActiveRecord::Migration[8.1]
  def change
    add_column :kiosks, :member_birthdays, :boolean, default: false, null: false
  end
end
