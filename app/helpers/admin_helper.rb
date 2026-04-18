module AdminHelper
  # Single source of truth for admin navigation sections and links.
  # Both the dashboard and the navbar partial iterate over this.
  def admin_nav_sections
    sections = []

    catalog_links = []
    catalog_links << { label: "Auctions",      icon: "bi-hammer",              path: admin_auctions_path                    } if policy(Auction).index?
    catalog_links << { label: "Categories",    icon: "bi-tags-fill",           path: admin_listings_categories_path         } if policy(Listings::Category).index?
    catalog_links << { label: "Galleries",     icon: "bi-images",              path: admin_galleries_path                   } if policy(Gallery).index?
    catalog_links << { label: "Listings",      icon: "bi-tag-fill",            path: admin_listings_path                    } if policy(Listing).index?
    catalog_links << { label: "Locations",     icon: "bi-geo-alt-fill",        path: admin_locations_path                   } if Current.tenant.features.locations? && policy(Location).index?
    catalog_links << { label: "Lots",          icon: "bi-map-fill",            path: admin_lots_path                        } if policy(Lot).index?
    catalog_links << { label: "Property Sets", icon: "bi-list-columns",        path: admin_listings_property_sets_path      } if policy(Listings::PropertySet).index?
    catalog_links << { label: "QR Codes",      icon: "bi-qr-code",             path: admin_qr_codes_path                    } if policy(QrCode).index?
    catalog_links << { label: "Registrations", icon: "bi-person-check",        path: admin_auction_registrations_path       } if policy(AuctionRegistration).index?
    sections << { title: "Catalog", icon: "bi-tag-fill", links: catalog_links } if catalog_links.any?

    sales_links = []
    sales_links << { label: "Delivery",           icon: "bi-truck",                  path: admin_listings_delivery_method_sets_path } if policy(DeliveryMethod).index?
    sales_links << { label: "Discounts",          icon: "bi-ticket-perforated-fill", path: admin_discount_codes_path                } if policy(DiscountCode).index?
    sales_links << { label: "Inquiries",          icon: "bi-chat-dots",              path: admin_inquiries_path                     } if policy(Inquiry).index?
    sales_links << { label: "Inquiry Forms",      icon: "bi-ui-checks",              path: admin_inquiry_forms_path                 } if policy(InquiryForm).index?
    sales_links << { label: "Invoices",           icon: "bi-receipt",                path: admin_invoices_path                      } if policy(Invoice).index?
    sales_links << { label: "Ledgers",            icon: "bi-journal-text",           path: admin_ledgers_path                       } if policy(Ledger).index?
    sales_links << { label: "Offers",             icon: "bi-tag",                    path: admin_offers_path                        } if policy(Offer).index?
    sales_links << { label: "Orders",             icon: "bi-bag",                    path: admin_orders_path                        } if policy(Order).index?
    sales_links << { label: "Subscription Plans", icon: "bi-card-checklist",         path: admin_subscription_plans_path            } if policy(SubscriptionPlan).index?
    sections << { title: "Sales", icon: "bi-basket-fill", links: sales_links } if sales_links.any?

    settings_links = []
    settings_links << { label: "Email Aliases", icon: "bi-envelope-at",       path: admin_email_aliases_path      } if policy(EmailAlias).index?
    settings_links << { label: "Navbar",        icon: "bi-list-ul",           path: admin_navbar_items_path       } if policy(NavbarItem).index?
    settings_links << { label: "Pages",         icon: "bi-file-earmark-text", path: admin_pages_path              } if policy(Page).index?
    settings_links << { label: "Roles",         icon: "bi-shield-fill",       path: admin_roles_path              } if policy(Role).index?
    settings_links << { label: "Sender Domain", icon: "bi-envelope-check",    path: admin_sender_signatures_path  } if policy(Postmark::Domain).index?
    settings_links << { label: "Tenant",        icon: "bi-globe",             path: admin_tenant_path             } if policy(Tenant).index?
    settings_links << { label: "Turnstile",     icon: "bi-shield-check",      path: admin_turnstiles_path         } if policy(Cloudflare::TurnstileWidget).index?
    settings_links << { label: "Users",         icon: "bi-people-fill",       path: admin_users_path              } if policy(User).index?
    sections << { title: "Settings", icon: "bi-gear-fill", links: settings_links } if settings_links.any?

    sections
  end
end
