class ApplicationController < ActionController::Base
  include Authentication
  include PauseProsopite
  include Pagy::Method

  around_action :scan_for_n_plus_one if Rails.env.local?
  before_action :set_current_tenant
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

  def set_current_tenant
    session[:tenant_key] = params[:tenant_key] if Rails.env.development? && params[:tenant_key].present?

    Current.tenant = if Rails.env.development? && session[:tenant_key].present?
      Tenant.find_by!(key: session[:tenant_key])
    elsif request.subdomain.present?
      Tenant.find_by!(key: request.subdomain)
    else
      Tenant.find_by!(default: true)
    end
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Tenant not found: #{request.subdomain}"
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
