module AuctionFeatureGated
  extend ActiveSupport::Concern

  included do
    before_action :require_auctions_feature!
  end

  private

  def require_auctions_feature!
    redirect_to root_path unless Current.tenant.features.auctions?
  end
end
