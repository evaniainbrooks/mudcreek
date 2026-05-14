require "rails_helper"

RSpec.describe PagesHelper, type: :helper do
  let(:tenant) { create(:tenant) }

  before { Current.tenant = tenant }
  after  { Current.tenant = nil }

  describe "#page_body_col_class" do
    let(:page) { create(:page) }

    context "when neither sidebar image is attached" do
      it "returns col-8" do
        expect(helper.page_body_col_class(page)).to eq("col-8")
      end
    end

    context "when only the left column image is attached" do
      before do
        page.left_column_image.attach(
          io: StringIO.new("img"),
          filename: "left.jpg",
          content_type: "image/jpeg"
        )
      end

      it "returns col-8" do
        expect(helper.page_body_col_class(page)).to eq("col-8")
      end
    end

    context "when only the right column image is attached" do
      before do
        page.right_column_image.attach(
          io: StringIO.new("img"),
          filename: "right.jpg",
          content_type: "image/jpeg"
        )
      end

      it "returns col-8" do
        expect(helper.page_body_col_class(page)).to eq("col-8")
      end
    end

    context "when both sidebar images are attached" do
      before do
        page.left_column_image.attach(
          io: StringIO.new("img"),
          filename: "left.jpg",
          content_type: "image/jpeg"
        )
        page.right_column_image.attach(
          io: StringIO.new("img"),
          filename: "right.jpg",
          content_type: "image/jpeg"
        )
      end

      it "returns col-4" do
        expect(helper.page_body_col_class(page)).to eq("col-4")
      end
    end
  end

  describe "#set_page_meta_tags" do
    let(:page) { create(:page, title: "About Us") }

    it "sets the title from the page title when no meta_title is present" do
      helper.set_page_meta_tags(page)

      expect(helper.meta_tags[:title]).to eq("About Us")
    end

    it "prefers meta_title over title when present" do
      page.update!(meta_title: "Custom Meta Title")

      helper.set_page_meta_tags(page)

      expect(helper.meta_tags[:title]).to eq("Custom Meta Title")
    end

    it "sets the og title" do
      helper.set_page_meta_tags(page)

      expect(helper.meta_tags[:og][:title]).to eq("About Us")
    end

    it "sets twitter card to summary when no hero image is attached" do
      helper.set_page_meta_tags(page)

      expect(helper.meta_tags[:twitter][:card]).to eq("summary")
    end

    it "sets twitter card to summary_large_image when a hero image is attached" do
      page.hero_image.attach(
        io: StringIO.new("img"),
        filename: "hero.jpg",
        content_type: "image/jpeg"
      )
      allow(Imgproxy.config).to receive(:endpoint).and_return(nil)

      helper.set_page_meta_tags(page)

      expect(helper.meta_tags[:twitter][:card]).to eq("summary_large_image")
    end
  end
end
