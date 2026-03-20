class OauthIdentity < ApplicationRecord
  include MultiTenant

  belongs_to :user

  encrypts :access_token, :refresh_token

  validates :provider, presence: true
  validates :uid,      presence: true
  validates :provider, uniqueness: { scope: :uid }
end
