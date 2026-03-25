module LocationFeatureGated
  extend ActiveSupport::Concern

  included do
    before_action :require_locations_feature!
  end

  private

  def require_locations_feature!
    raise ActionController::RoutingError, "Not Found" unless Current.tenant.features.locations?
  end
end
