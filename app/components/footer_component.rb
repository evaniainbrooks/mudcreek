class FooterComponent < ViewComponent::Base
  include CountriesHelper
  def initialize(tenant:)
    @tenant = tenant
  end

  private

  attr_reader :tenant

  def address
    @address ||= tenant.address
  end

  def footer_pages
    @footer_pages ||= Page.in_footer
  end

  def social_media_accounts
    @social_media_accounts ||= tenant.social_media_accounts.order(:position)
  end

  def social_media_url(account)
    base = case account.platform
    when "facebook"  then "https://facebook.com/"
    when "instagram" then "https://instagram.com/"
    when "youtube"   then "https://youtube.com/@"
    when "twitter"   then "https://x.com/"
    when "tiktok"    then "https://tiktok.com/@"
    when "snapchat"  then "https://snapchat.com/add/"
    when "linkedin"  then "https://linkedin.com/in/"
    when "discord"   then "https://discord.gg/"
    when "patreon"   then "https://patreon.com/"
    when "onlyfans"  then "https://onlyfans.com/"
    when "twitch"    then "https://twitch.tv/"
    end
    "#{base}#{account.slug}"
  end
end
