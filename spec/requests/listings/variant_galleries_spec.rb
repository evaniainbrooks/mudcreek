require "rails_helper"

RSpec.describe "Listings::VariantGalleries", type: :request do
  let(:browser_ua) { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36" }

  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let!(:listing) { create(:listing, published: true) }

  let(:turbo_headers) { { "HTTP_USER_AGENT" => browser_ua, "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" } }

  def get_gallery(listing, params: {}, headers: { "HTTP_USER_AGENT" => browser_ua })
    get listing_variant_gallery_path(listing), params: params, headers: headers
  end

  describe "GET /listings/:listing_hashid/variant_gallery" do
    context "when the listing has no gallery" do
      it "returns 200" do
        get_gallery(listing)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the listing has a gallery with photos" do
      before do
        gallery = Gallery.create!(name: "Test Gallery", listing: listing, tenant: Current.tenant)
        gallery.photos.attach(
          io: StringIO.new("fake image data"),
          filename: "photo.jpg",
          content_type: "image/jpeg"
        )
      end

      it "returns 200" do
        get_gallery(listing)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the listing is not published" do
      let!(:listing) { create(:listing, published: false) }

      it "returns 404" do
        get_gallery(listing)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      it "does not redirect to sign in (public endpoint)" do
        get_gallery(listing)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when requested via a Turbo frame (Accept includes text/vnd.turbo-stream.html)" do
      it "returns 200 rather than 406" do
        get_gallery(listing, headers: turbo_headers)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the tenant has listing_variants enabled" do
      before do
        Current.tenant.update!(features: { listing_variants: true })
      end

      let(:option) do
        Listings::Option.create!(listing: listing, name: "Size", position: 1, tenant: Current.tenant)
      end
      let(:small)  { Listings::OptionValue.create!(option: option, value: "Small",  position: 1) }
      let(:medium) { Listings::OptionValue.create!(option: option, value: "Medium", position: 2) }

      let!(:variant) do
        v = Listings::Variant.create!(listing: listing, tenant: Current.tenant)
        Listings::VariantOptionValue.create!(variant: v, option_value: small)
        v
      end

      context "with matching option_values params" do
        it "returns 200" do
          get_gallery(listing, params: { option_values: { option.id => small.id } })

          expect(response).to have_http_status(:ok)
        end
      end

      context "when option_values params are empty" do
        it "returns 200" do
          get_gallery(listing)

          expect(response).to have_http_status(:ok)
        end
      end

      context "when the matched variant has its own gallery photos" do
        before do
          gallery = Gallery.create!(name: "Small Gallery", variant: variant, tenant: Current.tenant)
          gallery.photos.attach(
            io: StringIO.new("fake variant image"),
            filename: "variant.jpg",
            content_type: "image/jpeg"
          )
        end

        it "returns 200 and includes the turbo frame" do
          get_gallery(listing, params: { option_values: { option.id => small.id } })

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("variant-gallery")
        end
      end

      context "with an affects_gallery option" do
        before { option.update!(affects_gallery: true) }

        it "returns 200 when given matching gallery option values" do
          get_gallery(listing, params: { option_values: { option.id => small.id } })

          expect(response).to have_http_status(:ok)
        end

        it "returns 200 and falls back to listing gallery when no variant matches" do
          get_gallery(listing, params: { option_values: { option.id => medium.id } })

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
