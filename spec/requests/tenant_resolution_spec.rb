require "rails_helper"

# TenantResolution is a concern included in ApplicationController.
# These specs exercise it through the public GET /auctions endpoint so that
# no authentication is required.
RSpec.describe TenantResolution, type: :request do
  describe "default-tenant resolution (no subdomain)" do
    before { host! "example.com" }

    context "when a default tenant exists" do
      before { Tenant.create!(name: "Default", key: "default", default: true) }

      it "resolves the tenant and returns 200" do
        get auctions_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "when no default tenant exists" do
      it "raises a routing error" do
        expect { get auctions_path }.to raise_error(ActionController::RoutingError, /Tenant not found/)
      end
    end
  end

  describe "subdomain-based resolution" do
    before { host! "acme.example.com" }

    context "when a tenant with a matching key exists" do
      before { Tenant.create!(name: "Acme", key: "acme", default: false) }

      it "resolves the tenant and returns 200" do
        get auctions_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "when no tenant matches the subdomain" do
      it "raises a routing error" do
        expect { get auctions_path }.to raise_error(ActionController::RoutingError, /Tenant not found/)
      end
    end
  end
end
