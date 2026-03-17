class AddShowVideoAsPosterToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :show_video_as_poster, :boolean, default: false, null: false
  end
end
