require "io/console"

namespace :tenant do
  desc "Create a new tenant with a super_admin role (all permissions) and an initial super admin user"
  task create: :environment do
    puts "=== Create New Tenant ==="
    puts

    # --- Tenant ---
    key  = prompt("Tenant key (lowercase letters, numbers, underscores)")
    name = prompt("Tenant name")

    tenant = Tenant.new(key: key, name: name, default: false, currency: "CAD")

    unless tenant.save
      abort "Failed to create tenant:\n  #{tenant.errors.full_messages.join("\n  ")}"
    end

    puts "  Tenant \"#{tenant.name}\" (#{tenant.key}) created."
    puts

    Current.tenant = tenant

    # --- Roles ---
    super_admin_role = Role.create!(
      name: "super_admin",
      description: "Full access to everything."
    )

    Role.create!(name: "admin",      description: "Full access to listings. No access to users or roles.")
    Role.create!(name: "user",       description: "Standard user with no admin permissions.")

    super_admin_role.grant_all_permissions!

    puts "  Roles created. #{Permission.count} permissions granted to super_admin."
    puts

    # --- Super admin user ---
    puts "=== Super Admin User ==="
    puts

    first_name = prompt("First name")
    last_name  = prompt("Last name")
    email      = prompt("Email address")
    password   = prompt("Password", secret: true)
    confirm    = prompt("Confirm password", secret: true)

    abort "Passwords do not match." unless password == confirm

    user = User.new(
      first_name:    first_name,
      last_name:     last_name,
      email_address: email,
      password:      password,
      role:          super_admin_role,
      activated_at:  Time.current
    )

    unless user.save
      abort "Failed to create user:\n  #{user.errors.full_messages.join("\n  ")}"
    end

    puts
    puts "  User #{user.name} <#{user.email_address}> created with super_admin role."
    puts
    puts "Done. Tenant \"#{tenant.name}\" is ready."
  end

  private

  def prompt(label, secret: false)
    print "  #{label}: "
    value = secret ? $stdin.noecho(&:gets)&.chomp : $stdin.gets&.chomp
    puts if secret
    abort "#{label} cannot be blank." if value.blank?
    value
  end
end
