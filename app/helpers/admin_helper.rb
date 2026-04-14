module AdminHelper
  def admin_catalog_nav?
    policy(Auction).index? ||
      policy(AuctionRegistration).index? ||
      policy(Listing).index? ||
      policy(Listings::Category).index? ||
      policy(Listings::PropertySet).index? ||
      policy(Lot).index? ||
      (Current.tenant.features.locations? && policy(Location).index?)
  end

  def admin_sales_nav?
    policy(DiscountCode).index? ||
      policy(Inquiry).index? ||
      policy(InquiryForm).index? ||
      policy(Invoice).index? ||
      policy(Ledger).index? ||
      policy(Listings::DeliveryMethodSet).index? ||
      policy(Offer).index? ||
      policy(Order).index? ||
      policy(SubscriptionPlan).index?
  end

  def admin_settings_nav?
    policy(NavbarItem).index? ||
      policy(Page).index? ||
      policy(EmailAlias).index? ||
      policy(SenderSignature).index? ||
      policy(QrCode).index? ||
      policy(Role).index? ||
      policy(Tenant).index? ||
      policy(User).index?
  end
end
