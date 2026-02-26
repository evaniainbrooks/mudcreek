Rails.application.config.to_prepare do
  TableCellComponent.register(User) do |user|
    helpers.link_to(user.email_address, helpers.admin_users_path(q: { email_address_eq: user.email_address }))
  end
end
