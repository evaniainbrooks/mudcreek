class Admin::Dashboard::NavSectionComponent < ViewComponent::Base
  def initialize(title:, links:)
    @title = title
    @links = links
  end

  def self.sections(view)
    catalog_links = []
    catalog_links << { label: "Listings",      icon: "bi-tag-fill",       path: view.admin_listings_path              } if view.policy(Listing).index?
    catalog_links << { label: "Auctions",      icon: "bi-hammer",         path: view.admin_auctions_path              } if view.policy(Auction).index?
    catalog_links << { label: "Registrations", icon: "bi-person-check",   path: view.admin_auction_registrations_path } if view.policy(AuctionRegistration).index?
    catalog_links << { label: "Categories",    icon: "bi-tags-fill",      path: view.admin_listings_categories_path              } if view.policy(Listings::Category).index?
    catalog_links << { label: "Property Sets", icon: "bi-list-columns",   path: view.admin_listings_property_sets_path           } if view.policy(Listings::PropertySet).index?
    catalog_links << { label: "Lots",          icon: "bi-map-fill",       path: view.admin_lots_path                             } if view.policy(Lot).index?

    sales_links = []
    sales_links << { label: "Orders",    icon: "bi-bag",                    path: view.admin_orders_path          } if view.policy(Order).index?
    sales_links << { label: "Invoices",  icon: "bi-receipt",                path: view.admin_invoices_path         } if view.policy(Invoice).index?
    sales_links << { label: "Offers",    icon: "bi-tag",                    path: view.admin_offers_path           } if view.policy(Offer).index?
    sales_links << { label: "Discounts", icon: "bi-ticket-perforated-fill", path: view.admin_discount_codes_path   } if view.policy(DiscountCode).index?
    sales_links << { label: "Delivery",  icon: "bi-truck",                  path: view.admin_listings_delivery_method_sets_path } if view.policy(DeliveryMethod).index?

    settings_links = []
    settings_links << { label: "Users",  icon: "bi-people-fill",         path: view.admin_users_path  } if view.policy(User).index?
    settings_links << { label: "Roles",  icon: "bi-shield-fill",         path: view.admin_roles_path  } if view.policy(Role).index?
    settings_links << { label: "Tenant", icon: "bi-globe",               path: view.admin_tenant_path } if view.policy(Tenant).index?
    settings_links << { label: "Pages",    icon: "bi-file-earmark-text",   path: view.admin_pages_path     } if view.policy(Page).index?
    settings_links << { label: "Locations", icon: "bi-geo-alt-fill",        path: view.admin_locations_path } if Current.tenant.features.locations? && view.policy(Location).index?
    settings_links << { label: "QR Codes", icon: "bi-qr-code",             path: view.admin_qr_codes_path  } if view.policy(QrCode).index?

    sections = []
    sections << { title: "Catalog",  links: catalog_links  } if catalog_links.any?
    sections << { title: "Sales",    links: sales_links    } if sales_links.any?
    sections << { title: "Settings", links: settings_links } if settings_links.any?
    sections
  end
end
