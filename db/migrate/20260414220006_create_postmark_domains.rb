class CreatePostmarkDomains < ActiveRecord::Migration[8.1]
  def change
    create_enum :postmark_domain_status, %w[unchecked verified failed]

    create_table :postmark_domains do |t|
      t.references :tenant, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :external_id, null: false
      t.enum :status, enum_type: :postmark_domain_status, default: "unchecked", null: false
      t.jsonb :api_response, null: false, default: {}

      t.timestamps
    end

    add_index :postmark_domains, :external_id, unique: true
  end
end
