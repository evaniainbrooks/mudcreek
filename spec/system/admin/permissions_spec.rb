require "rails_helper"

RSpec.describe "Admin::Permissions", type: :system do
  before { driven_by :rack_test }

  let(:admin_role) do
    create(:role).tap do |role|
      Permission::RESOURCES.each do |resource|
        Permission::ACTIONS.each do |action|
          role.permissions.create!(resource: resource, action: action)
        end
      end
    end
  end

  let(:current_user) { create(:user, role: admin_role) }
  let(:target_role) { create(:role) }

  before { sign_in_as(current_user) }

  describe "index" do
    it "shows the role name and Permissions heading" do
      visit admin_role_permissions_path(target_role)

      expect(page).to have_text(target_role.name)
      expect(page).to have_text("Permissions")
    end

    it "shows existing permissions in the table" do
      create(:permission, role: target_role, resource: "Listing", action: "create")

      visit admin_role_permissions_path(target_role)

      expect(page).to have_css("table td", text: "Listing")
      expect(page).to have_css("table td", text: "create")
    end

    it "shows the new permission form with resource and action selects" do
      visit admin_role_permissions_path(target_role)

      expect(page).to have_select("Resource")
      expect(page).to have_select("Action")
      expect(page).to have_button("Add Permission")
    end

    it "has a link back to the roles index" do
      visit admin_role_permissions_path(target_role)

      expect(page).to have_link("Roles", href: admin_roles_path)
    end

    it "redirects unauthenticated visitors to sign in" do
      click_link "Sign out"
      visit admin_role_permissions_path(target_role)

      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "create" do
    context "with valid attributes" do
      it "creates the permission and displays it in the table" do
        visit admin_role_permissions_path(target_role)

        select "Listing", from: "Resource"
        select "index", from: "Action"
        click_button "Add Permission"

        expect(page).to have_text("Permission was successfully added.")
        expect(page).to have_css("table td", text: "Listing")
        expect(page).to have_css("table td", text: "index")
      end

      it "allows adding multiple different permissions" do
        visit admin_role_permissions_path(target_role)
        select "Listing", from: "Resource"
        select "index", from: "Action"
        click_button "Add Permission"

        select "User", from: "Resource"
        select "show", from: "Action"
        click_button "Add Permission"

        expect(page).to have_css("table td", text: "Listing")
        expect(page).to have_css("table td", text: "User")
      end
    end

    context "with a duplicate resource and action combination" do
      it "shows an error alert and does not create a duplicate" do
        create(:permission, role: target_role, resource: "Listing", action: "index")

        visit admin_role_permissions_path(target_role)
        select "Listing", from: "Resource"
        select "index", from: "Action"
        click_button "Add Permission"

        expect(page).to have_text("Action has already been taken")
        expect(target_role.permissions.count).to eq(1)
      end
    end
  end

  describe "destroy" do
    let!(:permission) { create(:permission, role: target_role, resource: "Listing", action: "index") }

    it "deletes the permission and shows a success notice" do
      visit admin_role_permissions_path(target_role)
      click_button "Delete"

      expect(page).to have_text("Permission was successfully removed.")
      expect(page).not_to have_css("table td", text: "Listing")
    end

    it "does not delete other permissions on the same role" do
      other = create(:permission, role: target_role, resource: "User", action: "index")

      visit admin_role_permissions_path(target_role)

      within "tr", text: "Listing" do
        click_button "Delete"
      end

      expect(page).to have_css("table td", text: other.resource)
    end

    it "only deletes from the target role, not other roles" do
      other_role = create(:role)
      other_permission = create(:permission, role: other_role, resource: "Listing", action: "index")

      visit admin_role_permissions_path(target_role)
      click_button "Delete"

      expect(other_role.permissions).to include(other_permission)
    end
  end
end
