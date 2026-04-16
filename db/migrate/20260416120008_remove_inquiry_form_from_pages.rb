class RemoveInquiryFormFromPages < ActiveRecord::Migration[8.0]
  def up
    remove_foreign_key :pages, :inquiry_forms
    safety_assured { remove_column :pages, :inquiry_form_id }
  end

  def down
    add_column :pages, :inquiry_form_id, :bigint
    add_index :pages, :inquiry_form_id
    add_foreign_key :pages, :inquiry_forms, on_delete: :nullify
  end
end
