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

  helper_method :cart_item_count

  private

  def scan_for_n_plus_one
    Prosopite.scan
    yield
  ensure
    Prosopite.finish
  end

  def cart_item_count
    @cart_item_count ||= Current.user&.cart_items&.count || 0
  end

  def set_default_meta_tags
    set_meta_tags(
      site: "Mudcreek",
      og: { site_name: "Mudcreek", type: "website" },
      twitter: { card: "summary" }
    )
  end
end
