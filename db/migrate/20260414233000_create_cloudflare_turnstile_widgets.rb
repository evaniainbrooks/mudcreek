class CreateCloudflareTurnstileWidgets < ActiveRecord::Migration[8.1]
  def change
    create_table :cloudflare_turnstile_widgets do |t|
      t.references :tenant, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.string :external_id, null: false
      t.jsonb :api_response, null: false, default: {}

      t.timestamps
    end

    add_index :cloudflare_turnstile_widgets, :external_id, unique: true
  end
end
