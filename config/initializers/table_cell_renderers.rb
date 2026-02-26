Rails.application.config.to_prepare do
  TableCellComponent.register(User) do |user|
    helpers.link_to(user.email_address, helpers.admin_users_path(q: { email_address_eq: user.email_address }))
  end

  TableCellComponent.register(Role) do |role|
    helpers.link_to(role.name, helpers.admin_role_permissions_path(role))
  end

  TableCellComponent.register(Listing) do |listing|
    helpers.link_to(listing.name, helpers.admin_listing_path(listing))
  end
end
