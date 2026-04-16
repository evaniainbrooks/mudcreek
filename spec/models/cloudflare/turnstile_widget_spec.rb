require "rails_helper"

RSpec.describe Cloudflare::TurnstileWidget, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it "is valid with required attributes" do
      expect(build(:cloudflare_turnstile_widget)).to be_valid
    end

    it "requires external_id" do
      expect(build(:cloudflare_turnstile_widget, external_id: nil)).not_to be_valid
    end

    it "enforces uniqueness of external_id" do
      create(:cloudflare_turnstile_widget, external_id: "widget_abc")
      expect(build(:cloudflare_turnstile_widget, external_id: "widget_abc")).not_to be_valid
    end

    it "enforces one record per tenant" do
      create(:cloudflare_turnstile_widget)
      expect(build(:cloudflare_turnstile_widget)).not_to be_valid
    end
  end

  describe "api_response delegates" do
    subject(:widget) do
      build(:cloudflare_turnstile_widget, api_response: {
        "sitekey" => "0xSITE", "secret" => "0xSECRET",
        "name" => "My Widget", "domains" => ["example.com"], "mode" => "managed"
      })
    end

    it { expect(widget.sitekey).to eq("0xSITE") }
    it { expect(widget.secret).to eq("0xSECRET") }
    it { expect(widget.widget_name).to eq("My Widget") }
    it { expect(widget.domains).to eq(["example.com"]) }
    it { expect(widget.mode).to eq("managed") }
  end

  describe "multi-tenancy" do
    it "scopes records to the current tenant" do
      record = create(:cloudflare_turnstile_widget)
      Current.tenant = create(:tenant)
      expect(Cloudflare::TurnstileWidget.all).not_to include(record)
    end
  end
end
