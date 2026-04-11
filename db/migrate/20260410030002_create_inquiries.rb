class CreateInquiries < ActiveRecord::Migration[8.1]
  def change
    create_table :inquiries do |t|
      t.references :tenant,       null: false, foreign_key: true
      t.references :inquiry_form, null: false, foreign_key: true
      t.references :user,         null: true,  foreign_key: true
      t.string :name,    null: false
      t.string :email,   null: false
      t.string :phone
      t.text   :message, null: false

      t.timestamps
    end

    add_index :inquiries, [ :inquiry_form_id, :created_at ]
  end
end
