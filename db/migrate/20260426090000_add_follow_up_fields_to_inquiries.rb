class AddFollowUpFieldsToInquiries < ActiveRecord::Migration[8.1]
  def change
    create_enum :inquiry_status, %w[new in_progress resolved spam]

    add_column :inquiries, :status, :enum, enum_type: :inquiry_status, null: false, default: "new"
    add_column :inquiries, :admin_notes, :text
    add_column :inquiries, :followed_up_at, :datetime
  end
end
