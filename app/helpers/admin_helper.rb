module AdminHelper
  def admin_catalog_nav?
    policy(Listing).index? ||
      policy(Listings::Category).index? ||
      policy(Listings::PropertySet).index? ||
      policy(Lot).index? ||
      policy(Auction).index? ||
      policy(AuctionRegistration).index?
  end

  def admin_sales_nav?
    policy(Order).index? ||
      policy(Invoice).index? ||
      policy(Offer).index? ||
      policy(DiscountCode).index? ||
      policy(Listings::DeliveryMethodSet).index?
  end

  def admin_settings_nav?
    policy(User).index? || policy(Role).index? || policy(Tenant).index? || policy(Page).index?
  end
end
