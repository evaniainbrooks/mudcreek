class AddBackgroundTintOpacityToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :background_tint_opacity, :float, default: 0.5, null: false
  end
end
