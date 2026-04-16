class MigrateInquiryFormToContactFormWidgets < ActiveRecord::Migration[8.0]
  def up
    safety_assured { execute <<~SQL }
      INSERT INTO widgets (type, page_id, inquiry_form_id, position, tenant_id, created_at, updated_at)
      SELECT 'ContactFormWidget', id, inquiry_form_id, 0, tenant_id, NOW(), NOW()
      FROM pages
      WHERE inquiry_form_id IS NOT NULL
    SQL
  end

  def down
    safety_assured { execute "DELETE FROM widgets WHERE type = 'ContactFormWidget'" }
  end
end
