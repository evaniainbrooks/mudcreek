class CreateOauthIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_identities do |t|
      t.references :user,   null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.string  :provider,          null: false
      t.string  :uid,               null: false
      t.string  :email
      t.text    :access_token
      t.text    :refresh_token
      t.datetime :token_expires_at
      t.string  :name_from_provider

      t.timestamps
    end

    add_index :oauth_identities, [ :provider, :uid ], unique: true
  end
end
