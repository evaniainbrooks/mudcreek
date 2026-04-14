class CreateImprovmxDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :improvmx_domains do |t|
      t.references :tenant, null: false, foreign_key: { on_delete: :cascade }
      t.jsonb :api_response, null: false, default: {}

      t.timestamps
    end
  end
end
