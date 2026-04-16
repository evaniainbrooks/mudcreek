class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
  include TenantResolution

  around_action :scan_for_n_plus_one if Rails.env.local?
  include PauseProsopite
  before_action :resume_session
  before_action :set_default_meta_tags
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :cart_item_count, :offcanvas_cart_items, :offcanvas_watchlist_items, :watchlist_item_count

  BOT_USER_AGENT_PATTERN = /bot|crawl|slurp|spider|mediapartners|facebookexternalhit|ia_archiver|ahrefsbot|semrushbot|mj12bot|dotbot|petalbot|bytespider|meta-externalagent/i

  private

  def bot_request?
    ua = request.user_agent.to_s
    ua.empty? || BOT_USER_AGENT_PATTERN.match?(ua)
  end

  def scan_for_n_plus_one
    Prosopite.scan
    yield
  ensure
    Prosopite.finish
  end

  def offcanvas_cart_items
    @offcanvas_cart_items ||= if Current.user
      Current.user.cart_items.includes(listing: { images_attachments: :blob }).order(:created_at)
    elsif session[:guest_cart_token]
      CartItem.where(guest_cart_token: session[:guest_cart_token]).includes(listing: { images_attachments: :blob }).order(:created_at)
    else
      CartItem.none
    end
  end

  def offcanvas_watchlist_items
    @offcanvas_watchlist_items ||= if Current.user
      Current.user.watchlist_items.includes(listing: [:auction_listing, { images_attachments: :blob }]).order(:created_at)
    else
      WatchlistItem.none
    end
  end

  def watchlist_item_count
    @watchlist_item_count ||= Current.user ? Current.user.watchlist_items.count : 0
  end

  def cart_item_count
    @cart_item_count ||= if Current.user
      Current.user.cart_items.count
    elsif session[:guest_cart_token]
      CartItem.where(guest_cart_token: session[:guest_cart_token]).count
    else
      0
    end
  end

  def default_after_authentication_url
    if Current.tenant.features.user_verifications? && Current.user.verification.nil?
      profile_verification_url
    else
      root_url
    end
  end

  def set_default_meta_tags
    set_meta_tags(
      site: Current.tenant.name,
      og: { site_name: Current.tenant.name, type: "website", url: request.original_url },
      twitter: { card: "summary" }
    )
  end
end
