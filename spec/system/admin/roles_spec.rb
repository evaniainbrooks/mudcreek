require "rails_helper"

RSpec.describe "Admin::Roles", type: :system do
  before { driven_by :rack_test }

  let(:current_user) { create(:user, :super_admin) }

  before { sign_in_as(current_user) }

  describe "index" do
    let!(:role) { create(:role) }

    it "shows the roles heading and table" do
      visit admin_roles_path

      expect(page).to have_text("Roles")
      expect(page).to have_css("table")
    end

    it "displays the role name and description" do
      visit admin_roles_path

      expect(page).to have_text(role.name)
      expect(page).to have_text(role.description)
    end

    it "displays the number of users assigned to each role" do
      create_list(:user, 3, role: role)
      visit admin_roles_path

      expect(page).to have_text("3")
    end

    it "shows the new role form with name and description fields" do
      visit admin_roles_path

      expect(page).to have_field("Name")
      expect(page).to have_field("Description")
      expect(page).to have_button("Add Role")
    end

    it "redirects unauthenticated visitors to sign in" do
      click_link "Sign out"
      visit admin_roles_path

      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "create" do
    context "with valid attributes" do
      it "creates the role and displays it in the table" do
        visit admin_roles_path

        fill_in "Name", with: "buyer"
        fill_in "Description", with: "A person looking to buy property"
        click_button "Add Role"

        expect(page).to have_text('Role "buyer" was successfully created.')
        expect(page).to have_text("buyer")
        expect(page).to have_text("A person looking to buy property")
      end
    end

    context "with missing name" do
      it "re-renders the form with a validation error" do
        visit admin_roles_path

        fill_in "Description", with: "Some description"
        click_button "Add Role"

        expect(page).to have_text("Name can't be blank")
      end
    end

    context "with missing description" do
      it "re-renders the form with a validation error" do
        visit admin_roles_path

        fill_in "Name", with: "buyer"
        click_button "Add Role"

        expect(page).to have_text("Description can't be blank")
      end
    end

    context "with a duplicate name" do
      let!(:existing_role) { create(:role, name: "buyer") }

      it "re-renders the form with a uniqueness error" do
        visit admin_roles_path

        fill_in "Name", with: "buyer"
        fill_in "Description", with: "Another description"
        click_button "Add Role"

        expect(page).to have_text("Name has already been taken")
      end
    end
  end

  describe "destroy" do
    let!(:role) { create(:role) }

    it "deletes the role and shows a success notice" do
      visit admin_roles_path

      name = role.name
      within "tr", text: name do
        click_button "Delete"
      end

      expect(page).to have_text("Role \"#{name}\" was successfully deleted.")
      expect(page).to have_current_path(admin_roles_path)
      expect(page).not_to have_css("table td", text: name)
    end

    it "does not delete other roles" do
      other_role = create(:role)
      visit admin_roles_path

      within "tr", text: role.name do
        click_button "Delete"
      end

      expect(page).to have_text(other_role.name)
    end
  end
end
