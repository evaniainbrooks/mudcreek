require "rails_helper"

RSpec.describe ProvisionCloudflareTurnstileJob, type: :job do
  let(:tenant) { Tenant.create!(key: "test", name: "Acme", default: true, custom_domain: "acme.example.com") }
  let(:client) { instance_double(CloudflareClient) }

  before do
    allow(CloudflareClient).to receive(:new).and_return(client)
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
  end

  def stub_list(*widgets)
    allow(client).to receive(:list_widgets).with(page: 1, per_page: 25)
                                           .and_return({ success: true, widgets: widgets })
    allow(client).to receive(:list_widgets).with(page: 2, per_page: 25)
                                           .and_return({ success: true, widgets: [] })
  end

  describe "#perform" do
    context "when the tenant has no custom domain" do
      before { tenant.update!(custom_domain: nil) }

      it "does nothing" do
        stub_list
        described_class.new.perform(tenant.id)

        expect(client).not_to have_received(:list_widgets)
        expect(Cloudflare::TurnstileWidget.count).to eq(0)
      end
    end

    context "when the domain is already registered to an existing widget" do
      let(:existing_widget) do
        { "sitekey" => "0xEXIST", "name" => "Existing", "domains" => [ "acme.example.com" ], "mode" => "managed" }
      end

      it "creates a TurnstileWidget record with the existing sitekey" do
        stub_list(existing_widget)

        expect {
          described_class.new.perform(tenant.id)
        }.to change(Cloudflare::TurnstileWidget, :count).by(1)

        expect(Cloudflare::TurnstileWidget.last.external_id).to eq("0xEXIST")
      end

      it "does not call update_widget or create_widget" do
        stub_list(existing_widget)
        allow(client).to receive(:update_widget)
        allow(client).to receive(:create_widget)

        described_class.new.perform(tenant.id)

        expect(client).not_to have_received(:update_widget)
        expect(client).not_to have_received(:create_widget)
      end

      it "broadcasts the widget status" do
        stub_list(existing_widget)
        described_class.new.perform(tenant.id)

        expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to)
          .with("cloudflare_turnstile_#{tenant.id}", hash_including(target: "turnstile-widget-status"))
      end
    end

    context "when a widget has capacity (fewer than 10 domains)" do
      let(:candidate) do
        { "sitekey" => "0xCAND", "name" => "Shared", "domains" => [ "other.example.com" ], "mode" => "managed" }
      end
      let(:updated_widget) { candidate.merge("domains" => [ "other.example.com", "acme.example.com" ]) }

      before do
        stub_list(candidate)
        allow(client).to receive(:update_widget).and_return({ success: true, widget: updated_widget })
      end

      it "adds the domain to the candidate widget" do
        described_class.new.perform(tenant.id)

        expect(client).to have_received(:update_widget).with(
          "0xCAND",
          name: "Shared",
          domains: [ "other.example.com", "acme.example.com" ],
          mode: "managed"
        )
      end

      it "saves the candidate sitekey" do
        described_class.new.perform(tenant.id)

        expect(Cloudflare::TurnstileWidget.last.external_id).to eq("0xCAND")
      end
    end

    context "when no suitable widget exists" do
      let(:new_widget) { { "sitekey" => "0xNEW", "name" => "Acme Turnstile", "domains" => [ "acme.example.com" ], "mode" => "managed" } }

      before do
        stub_list
        allow(client).to receive(:create_widget).and_return({ success: true, widget: new_widget })
      end

      it "creates a new Cloudflare widget" do
        described_class.new.perform(tenant.id)

        expect(client).to have_received(:create_widget).with(
          name: "Acme Turnstile",
          domains: [ "acme.example.com" ],
          mode: "managed"
        )
      end

      it "persists the new sitekey" do
        described_class.new.perform(tenant.id)

        expect(Cloudflare::TurnstileWidget.last.external_id).to eq("0xNEW")
      end
    end

    context "when create_widget fails" do
      before do
        stub_list
        allow(client).to receive(:create_widget).and_return({ success: false, widget: nil })
      end

      it "does not create a TurnstileWidget record" do
        expect {
          described_class.new.perform(tenant.id)
        }.not_to change(Cloudflare::TurnstileWidget, :count)
      end
    end

    context "when the widget record already exists" do
      let!(:existing_record) { create(:cloudflare_turnstile_widget, tenant: tenant, external_id: "0xOLD") }
      let(:found_widget) { { "sitekey" => "0xOLD", "name" => "Old", "domains" => [ "acme.example.com" ], "mode" => "managed" } }

      it "updates rather than duplicates the record" do
        stub_list(found_widget)

        expect {
          described_class.new.perform(tenant.id)
        }.not_to change(Cloudflare::TurnstileWidget, :count)

        expect(existing_record.reload.external_id).to eq("0xOLD")
      end
    end
  end
end
