class AddRedirectPathToInquiryForms < ActiveRecord::Migration[8.1]
  def change
    add_column :inquiry_forms, :redirect_path, :string, null: false, default: "/"
  end
end
