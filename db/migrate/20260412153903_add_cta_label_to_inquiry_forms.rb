class AddCtaLabelToInquiryForms < ActiveRecord::Migration[8.1]
  def change
    add_column :inquiry_forms, :cta_label, :string, default: "Send Message", null: false
  end
end
