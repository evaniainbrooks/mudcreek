class CreateSocialMediaAccounts < ActiveRecord::Migration[8.1]
  def up
    create_enum :social_media_platform, %w[
      facebook instagram youtube twitter tiktok snapchat linkedin discord patreon onlyfans twitch
    ]

    create_table :social_media_accounts do |t|
      t.references :tenant, null: false, foreign_key: true
      t.enum :platform, enum_type: :social_media_platform, null: false
      t.string :slug, null: false
      t.string :icon, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :social_media_accounts, [:tenant_id, :platform], unique: true
  end

  def down
    drop_table :social_media_accounts
    drop_enum :social_media_platform
  end
end
