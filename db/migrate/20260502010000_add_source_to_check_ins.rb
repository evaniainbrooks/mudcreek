class AddSourceToCheckIns < ActiveRecord::Migration[8.1]
  def change
    create_enum :check_in_source, %w[kiosk schedule admin]

    add_column :check_ins, :source, :enum, enum_type: :check_in_source, null: false, default: "kiosk"
  end
end
