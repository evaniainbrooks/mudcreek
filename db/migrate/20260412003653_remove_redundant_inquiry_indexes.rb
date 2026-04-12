class RemoveRedundantInquiryIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :inquiry_forms, :tenant_id, name: "index_inquiry_forms_on_tenant_id"
    remove_index :inquiries, :inquiry_form_id, name: "index_inquiries_on_inquiry_form_id"
  end
end
