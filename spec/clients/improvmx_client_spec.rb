require "rails_helper"

RSpec.describe ImprovmxClient do
  subject(:client) { described_class.new("test-api-key") }

  describe "#check_domain" do
    let(:domain) { "example.com" }

    def stub_check(body)
      response = instance_double(Net::HTTPResponse, body: body.to_json)
      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(http).to receive(:request).and_return(response)
    end

    context "when DNS records are valid" do
      before do
        stub_check(
          "success" => true,
          "errors" => [],
          "records" => {
            "valid" => true,
            "mx" => { "valid" => true },
            "spf" => { "valid" => true }
          }
        )
      end

      it "returns success: true" do
        expect(client.check_domain(domain)[:success]).to be true
      end
    end

    context "when the API call succeeds but DNS records are invalid" do
      before do
        stub_check(
          "success" => true,
          "errors" => [],
          "records" => {
            "valid" => false,
            "error" => "The requested domain was not found.",
            "mx" => { "valid" => false, "values" => nil, "expected" => [ "mx1.improvmx.com", "mx2.improvmx.com" ] },
            "spf" => { "valid" => false, "values" => nil, "expected" => "v=spf1 include:spf.improvmx.com ~all" }
          }
        )
      end

      it "returns success: false" do
        expect(client.check_domain(domain)[:success]).to be false
      end

      it "still returns the records for display" do
        result = client.check_domain(domain)
        expect(result[:records]).to include("valid" => false)
      end
    end

    context "when the API call itself fails" do
      before do
        stub_check("success" => false, "errors" => [ "Unauthorized" ], "records" => [])
      end

      it "returns success: false" do
        expect(client.check_domain(domain)[:success]).to be false
      end
    end

    context "when a network error occurs" do
      before do
        allow(Net::HTTP).to receive(:start).and_raise(SocketError.new("connection failed"))
      end

      it "returns success: false" do
        expect(client.check_domain(domain)[:success]).to be false
      end

      it "includes the error message" do
        expect(client.check_domain(domain)[:errors]).to include("connection failed")
      end
    end
  end
end
