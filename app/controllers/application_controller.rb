class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method

  before_action :set_current_tenant
  before_action :resume_session
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :cart_item_count

  private

  def set_current_tenant
    Current.tenant = if request.subdomain.present?
      Tenant.find_by!(key: request.subdomain)
    else
      Tenant.find_by!(default: true)
    end
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Tenant not found: #{request.subdomain}"
  end

  def cart_item_count
    Current.user&.cart_items&.count || 0
  end
end
