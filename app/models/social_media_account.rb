class SocialMediaAccount < ApplicationRecord
  include NativeEnum

  PLATFORM_ICONS = {
    "facebook"  => "bi-facebook",
    "instagram" => "bi-instagram",
    "youtube"   => "bi-youtube",
    "twitter"   => "bi-twitter-x",
    "tiktok"    => "bi-tiktok",
    "snapchat"  => "bi-snapchat",
    "linkedin"  => "bi-linkedin",
    "discord"   => "bi-discord",
    "patreon"   => "bi-patreon",
    "onlyfans"  => "bi-person-heart",
    "twitch"    => "bi-twitch"
  }.freeze

  belongs_to :tenant

  native_enum :platform, %i[facebook instagram youtube twitter tiktok snapchat linkedin discord patreon onlyfans twitch]

  validates :platform, presence: true
  validates :slug, presence: true
  validates :icon, presence: true
  validates :platform, uniqueness: { scope: :tenant_id }

  before_validation :set_default_icon

  acts_as_list scope: :tenant

  private

  def set_default_icon
    self.icon = PLATFORM_ICONS[platform] if icon.blank? && platform.present?
  end
end
