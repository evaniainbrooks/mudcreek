class AddInquiryFormIdToPages < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :pages, :inquiry_form_id, :bigint
    add_index :pages, :inquiry_form_id, algorithm: :concurrently
  end
end
