require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  let(:tenant) { create(:tenant) }

  before { Current.tenant = tenant }
  after  { Current.tenant = nil }

  describe "#bootstrap_flash_class" do
    it { expect(helper.bootstrap_flash_class("notice")).to eq("success") }
    it { expect(helper.bootstrap_flash_class("alert")).to eq("danger") }
    it { expect(helper.bootstrap_flash_class("warning")).to eq("warning") }
    it { expect(helper.bootstrap_flash_class("info")).to eq("info") }
    it { expect(helper.bootstrap_flash_class("unknown")).to eq("secondary") }
    it { expect(helper.bootstrap_flash_class(:notice)).to eq("success") }
  end

  describe "#document_icon_class" do
    it { expect(helper.document_icon_class("application/pdf")).to eq("bi-file-pdf") }
    it { expect(helper.document_icon_class("application/msword")).to eq("bi-file-word") }
    it { expect(helper.document_icon_class("application/vnd.openxmlformats-officedocument.wordprocessingml.document")).to eq("bi-file-word") }
    it { expect(helper.document_icon_class("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")).to eq("bi-file-excel") }
    it { expect(helper.document_icon_class("image/jpeg")).to eq("bi-file-earmark") }
    it { expect(helper.document_icon_class("")).to eq("bi-file-earmark") }
  end

  describe "#registration_status" do
    context "when unauthenticated" do
      it "returns 'unauthenticated'" do
        expect(helper.registration_status(nil)).to eq("unauthenticated")
      end
    end

    context "when authenticated" do
      before { Current.session = double(user: create(:user)) }
      after  { Current.session = nil }

      it "returns 'none' when registration is nil" do
        expect(helper.registration_status(nil)).to eq("none")
      end

      it "returns the registration state when a registration is present" do
        registration = double(state: "approved")
        expect(helper.registration_status(registration)).to eq("approved")
      end
    end
  end

  describe "#user_bid_token" do
    it "returns nil when given nil" do
      expect(helper.user_bid_token(nil)).to be_nil
    end

    it "returns a hex string for an integer id" do
      result = helper.user_bid_token(42)
      expect(result).to match(/\A[0-9a-f]{64}\z/)
    end

    it "returns a hex string for a user object" do
      user = create(:user)
      result = helper.user_bid_token(user)
      expect(result).to match(/\A[0-9a-f]{64}\z/)
    end

    it "returns the same value for a user object and its id" do
      user = create(:user)
      expect(helper.user_bid_token(user)).to eq(helper.user_bid_token(user.id))
    end

    it "returns different values for different ids" do
      expect(helper.user_bid_token(1)).not_to eq(helper.user_bid_token(2))
    end
  end

  describe "#browse_tabs" do
    context "when auctions feature is off and no categories exist" do
      it "returns nil" do
        expect(helper.browse_tabs(active: :listings)).to be_nil
      end
    end

    context "when auctions feature is enabled" do
      let(:tenant) { create(:tenant, features: { auctions: true }) }

      it "renders the Auctions tab" do
        html = Capybara.string(helper.browse_tabs(active: :listings).to_s)
        expect(html).to have_link("Auctions")
      end

      it "renders the Listings tab" do
        html = Capybara.string(helper.browse_tabs(active: :listings).to_s)
        expect(html).to have_link("Listings")
      end

      it "does not render a Categories tab" do
        html = Capybara.string(helper.browse_tabs(active: :listings).to_s)
        expect(html).not_to have_link("Categories")
      end

      it "marks the active tab with 'active' class" do
        html = Capybara.string(helper.browse_tabs(active: :auctions).to_s)
        expect(html).to have_css("a.nav-link.active", text: "Auctions")
      end

      it "does not mark inactive tabs as active" do
        html = Capybara.string(helper.browse_tabs(active: :auctions).to_s)
        expect(html).not_to have_css("a.nav-link.active", text: "Listings")
      end
    end

    context "when categories exist but auctions feature is off" do
      before { create(:listings_category) }

      it "renders the Listings tab" do
        html = Capybara.string(helper.browse_tabs(active: :listings).to_s)
        expect(html).to have_link("Listings")
      end

      it "renders the Categories tab" do
        html = Capybara.string(helper.browse_tabs(active: :listings).to_s)
        expect(html).to have_link("Categories")
      end

      it "does not render the Auctions tab" do
        html = Capybara.string(helper.browse_tabs(active: :listings).to_s)
        expect(html).not_to have_link("Auctions")
      end
    end

    context "when both auctions feature is enabled and categories exist" do
      let(:tenant) { create(:tenant, features: { auctions: true }) }

      before { create(:listings_category) }

      it "renders all three tabs" do
        html = Capybara.string(helper.browse_tabs(active: :listings).to_s)
        expect(html).to have_link("Auctions")
        expect(html).to have_link("Listings")
        expect(html).to have_link("Categories")
      end
    end
  end

  describe "#tenant_theme_tag" do
    context "when no custom colors are set" do
      it "returns a style tag with navbar defaults" do
        html = helper.tenant_theme_tag(tenant)
        expect(html).to include("<style>")
        expect(html).to include(".navbar")
      end
    end

    context "with a primary color" do
      let(:tenant) { create(:tenant, primary_color: "#3a7d44") }

      it "returns a style tag" do
        html = helper.tenant_theme_tag(tenant)
        expect(html).to include("<style>")
      end

      it "includes the primary color CSS variable" do
        html = helper.tenant_theme_tag(tenant)
        expect(html).to include("--bs-primary: #3a7d44")
      end

      it "includes the rgb conversion" do
        html = helper.tenant_theme_tag(tenant)
        expect(html).to include("--bs-primary-rgb: 58, 125, 68")
      end

      it "includes button overrides" do
        html = helper.tenant_theme_tag(tenant)
        expect(html).to include(".btn-primary")
        expect(html).to include(".btn-outline-primary")
      end
    end

    context "with a secondary color" do
      let(:tenant) { create(:tenant, secondary_color: "#c0392b") }

      it "includes secondary CSS variable" do
        html = helper.tenant_theme_tag(tenant)
        expect(html).to include("--bs-secondary: #c0392b")
      end

      it "includes .btn-secondary overrides" do
        html = helper.tenant_theme_tag(tenant)
        expect(html).to include(".btn-secondary")
      end
    end

    context "with a footer color" do
      let(:tenant) { create(:tenant, footer_color: "#222222") }

      it "includes footer CSS rule" do
        html = helper.tenant_theme_tag(tenant)
        expect(html).to include("footer.bg-body-tertiary")
        expect(html).to include("#222222")
      end
    end

    context "with a tertiary color" do
      let(:tenant) { create(:tenant, tertiary_color: "#888888") }

      it "includes tertiary CSS rules" do
        html = helper.tenant_theme_tag(tenant)
        expect(html).to include(".text-tertiary")
        expect(html).to include(".bg-tertiary")
      end
    end

    context "with card and container colors" do
      let(:tenant) { create(:tenant, card_color: "#f5f5f5", container_color: "#ffffff") }

      it "includes the card background variable" do
        html = helper.tenant_theme_tag(tenant)
        expect(html).to include("--bs-card-bg: #f5f5f5")
      end

      it "includes the container background variable" do
        html = helper.tenant_theme_tag(tenant)
        expect(html).to include("--app-card-bg: #ffffff")
      end
    end

    context "with a shorthand hex color (#abc)" do
      let(:tenant) { create(:tenant, primary_color: "#abc") }

      it "expands the shorthand and returns a valid style tag" do
        html = helper.tenant_theme_tag(tenant)
        expect(html).to include("--bs-primary: #abc")
        # rgb of #aabbcc = 170, 187, 204
        expect(html).to include("--bs-primary-rgb: 170, 187, 204")
      end
    end
  end

  describe "#google_maps_embed_url" do
    before { allow(helper).to receive(:google_maps_api_key).and_return(nil) }

    let(:address) do
      double(
        geocoded?: false,
        to_geocode_string: "123 Main St, Calgary, AB"
      )
    end

    it "returns a google maps embed URL" do
      url = helper.google_maps_embed_url(address)
      expect(url).to include("maps.google.com")
    end

    it "encodes the address in the query" do
      url = helper.google_maps_embed_url(address)
      expect(url).to include("Calgary")
    end

    context "when the address is geocoded" do
      let(:address) { double(geocoded?: true, latitude: 51.045, longitude: -114.057) }

      it "uses coordinates instead of the address string" do
        url = helper.google_maps_embed_url(address)
        expect(url).to include("51.045")
        expect(url).to include("-114.057")
      end
    end

    context "when an API key is configured" do
      before { allow(helper).to receive(:google_maps_api_key).and_return("test-key") }

      it "uses the embed API URL" do
        url = helper.google_maps_embed_url(address)
        expect(url).to include("google.com/maps/embed/v1/place")
        expect(url).to include("key=test-key")
      end
    end
  end

  describe "#inline_edit_cell" do
    let(:user) { create(:user) }
    let(:url)  { "/admin/users/#{user.id}" }

    subject(:html) do
      Capybara.string(helper.inline_edit_cell(user, :first_name, "Alice", url: url, scope: :user).to_s)
    end

    it "renders a wrapper div with the record-field dom id" do
      expect(html).to have_css("#user_#{user.id}_first_name")
    end

    it "shows the display span with the value" do
      expect(html).to have_css("[data-inline-edit-target='display']", text: "Alice")
    end

    it "hides the form initially" do
      expect(html).to have_css("[data-inline-edit-target='form']", visible: :hidden)
    end

    context "when value is blank" do
      subject(:html) do
        Capybara.string(helper.inline_edit_cell(user, :first_name, "", url: url, scope: :user).to_s)
      end

      it "shows — as the placeholder" do
        expect(html).to have_css("[data-inline-edit-target='display']", text: "—")
      end
    end

    context "when the record has an error on the field" do
      before { user.errors.add(:first_name, "can't be blank") }

      subject(:html) do
        Capybara.string(helper.inline_edit_cell(user, :first_name, "", url: url, scope: :user).to_s)
      end

      it "shows the error message" do
        expect(html.native.to_s).to include("can't be blank")
      end

      it "hides the display span" do
        expect(html).to have_css("[data-inline-edit-target='display']", visible: :hidden)
      end

      it "reveals the form" do
        expect(html).to have_css("[data-inline-edit-target='form']", visible: :visible)
      end
    end
  end
end
