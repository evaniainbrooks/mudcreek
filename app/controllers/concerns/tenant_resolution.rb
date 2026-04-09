# frozen_string_literal: true

module TenantResolution
  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_current_tenant
    around_action :set_time_zone
  end

  private

  def set_current_tenant
    session[:tenant_key] = params[:tenant_key] if params[:tenant_key].present?

    Current.tenant = if session[:tenant_key].present?
      Tenant.find_by!(key: session[:tenant_key])
    elsif request.subdomain.present?
      Tenant.find_by!(key: request.subdomain)
    else
      Tenant.find_by!(default: true)
    end
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Tenant not found: #{request.subdomain}"
  end

  def set_time_zone
    tz = Current.tenant&.timezone.presence || "UTC"
    Time.use_zone(tz) { yield }
  end
end
