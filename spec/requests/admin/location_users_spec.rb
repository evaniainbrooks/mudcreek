require "rails_helper"

RSpec.describe "Admin::LocationUsers", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  # UserLocation is not in Permission::RESOURCES, so only super_admins can
  # create/destroy via the standard permission system.
  let(:admin)    { create(:user, :super_admin) }
  let(:member)   { create(:user) }
  let(:location) { create(:location) }

  before { post session_path, params: { email_address: admin.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "POST /admin/locations/:location_hashid/location_users" do
    it "adds the user to the location and redirects" do
      expect {
        post admin_location_location_users_path(location), params: { user_id: member.id }
      }.to change(UserLocation, :count).by(1)

      expect(response).to redirect_to(admin_location_path(location))
    end

    it "redirects even when the user is already a member (save fails silently)" do
      location.user_locations.create!(user: member, tenant: Current.tenant)

      expect {
        post admin_location_location_users_path(location), params: { user_id: member.id }
      }.not_to change(UserLocation, :count)

      expect(response).to redirect_to(admin_location_path(location))
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_location_location_users_path(location), params: { user_id: member.id }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks permission" do
      let(:admin) { create(:user) }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_location_location_users_path(location), params: { user_id: member.id }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/locations/:location_hashid/location_users/:id" do
    let!(:user_location) { location.user_locations.create!(user: member, tenant: Current.tenant) }

    it "removes the user from the location" do
      expect {
        delete admin_location_location_user_path(location, user_location)
      }.to change(UserLocation, :count).by(-1)
    end

    it "redirects to the location page" do
      delete admin_location_location_user_path(location, user_location)

      expect(response).to redirect_to(admin_location_path(location))
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_location_location_user_path(location, user_location)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks permission" do
      let(:admin) { create(:user) }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_location_location_user_path(location, user_location)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
