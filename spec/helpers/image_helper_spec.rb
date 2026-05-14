require "rails_helper"

RSpec.describe ImageHelper, type: :helper do
  let(:attachment) { double("attachment") }

  describe "#optimized_image_url" do
    context "when imgproxy is not configured" do
      before { allow(Imgproxy.config).to receive(:endpoint).and_return(nil) }

      it "delegates to url_for" do
        allow(helper).to receive(:url_for).with(attachment).and_return("/rails/active_storage/blobs/photo.jpg")

        url = helper.optimized_image_url(attachment, preset: :card)

        expect(url).to eq("/rails/active_storage/blobs/photo.jpg")
      end
    end

    context "when imgproxy is configured" do
      before { allow(Imgproxy.config).to receive(:endpoint).and_return("https://imgproxy.example.com") }

      it "delegates to Imgproxy.url_for with the preset options" do
        allow(Imgproxy).to receive(:url_for)
          .with(attachment, **ImageHelper::IMGPROXY_PRESETS[:card])
          .and_return("https://imgproxy.example.com/signed/photo.jpg")

        url = helper.optimized_image_url(attachment, preset: :card)

        expect(url).to eq("https://imgproxy.example.com/signed/photo.jpg")
      end

      it "uses the logo preset options for :logo" do
        allow(Imgproxy).to receive(:url_for)
          .with(attachment, **ImageHelper::IMGPROXY_PRESETS[:logo])
          .and_return("https://imgproxy.example.com/logo.jpg")

        url = helper.optimized_image_url(attachment, preset: :logo)

        expect(url).to eq("https://imgproxy.example.com/logo.jpg")
      end
    end
  end

  describe "#absolute_optimized_image_url" do
    before { allow(Imgproxy.config).to receive(:endpoint).and_return(nil) }

    context "when the URL is already absolute" do
      it "returns it unchanged" do
        allow(helper).to receive(:url_for).and_return("https://cdn.example.com/photo.jpg")

        url = helper.absolute_optimized_image_url(attachment)

        expect(url).to eq("https://cdn.example.com/photo.jpg")
      end
    end

    context "when the URL is relative" do
      it "prepends the request base URL" do
        allow(helper).to receive(:url_for).and_return("/rails/active_storage/blobs/photo.jpg")

        url = helper.absolute_optimized_image_url(attachment)

        expect(url).to start_with("http")
        expect(url).to end_with("/rails/active_storage/blobs/photo.jpg")
      end
    end
  end

  describe "#background_image_style" do
    before { allow(Imgproxy.config).to receive(:endpoint).and_return(nil) }

    it "includes the image URL" do
      allow(helper).to receive(:url_for).and_return("/photo.jpg")

      style = helper.background_image_style(attachment)

      expect(style).to include("url('/photo.jpg')")
    end

    it "includes the default height" do
      allow(helper).to receive(:url_for).and_return("/photo.jpg")

      style = helper.background_image_style(attachment)

      expect(style).to include("height: 200px")
    end

    it "uses the given height" do
      allow(helper).to receive(:url_for).and_return("/photo.jpg")

      style = helper.background_image_style(attachment, height: 400)

      expect(style).to include("height: 400px")
    end

    it "includes background-size contain" do
      allow(helper).to receive(:url_for).and_return("/photo.jpg")

      style = helper.background_image_style(attachment)

      expect(style).to include("background-size: contain")
    end
  end

  describe "#optimized_image_tag" do
    context "when imgproxy is not configured" do
      before { allow(Imgproxy.config).to receive(:endpoint).and_return(nil) }

      it "renders an image tag with the attachment" do
        allow(helper).to receive(:image_tag).with(attachment, alt: "Photo").and_return('<img src="photo.jpg">')

        result = helper.optimized_image_tag(attachment, preset: :card, alt: "Photo")

        expect(result).to eq('<img src="photo.jpg">')
      end
    end

    context "when imgproxy is configured" do
      before { allow(Imgproxy.config).to receive(:endpoint).and_return("https://imgproxy.example.com") }

      it "renders an image tag with the imgproxy URL" do
        allow(Imgproxy).to receive(:url_for)
          .with(attachment, **ImageHelper::IMGPROXY_PRESETS[:card])
          .and_return("https://imgproxy.example.com/signed/photo.jpg")

        result = helper.optimized_image_tag(attachment, preset: :card, alt: "Photo")

        expect(result).to include("imgproxy.example.com")
      end
    end
  end
end
