require "rails_helper"

RSpec.describe Page, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:tenant) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:slug) }

    it "accepts a valid slug" do
      page = build(:page, slug: "about-us-2")
      expect(page).to be_valid
    end

    it "rejects a slug with uppercase letters" do
      page = build(:page, slug: "About-Us")
      expect(page).not_to be_valid
      expect(page.errors[:slug]).to be_present
    end

    it "rejects a slug with spaces" do
      page = build(:page, slug: "about us")
      expect(page).not_to be_valid
      expect(page.errors[:slug]).to be_present
    end

    it "rejects a slug with special characters" do
      page = build(:page, slug: "about_us!")
      expect(page).not_to be_valid
      expect(page.errors[:slug]).to be_present
    end

    it "rejects a duplicate slug within the same tenant" do
      create(:page, slug: "terms")
      duplicate = build(:page, slug: "terms")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to be_present
    end
  end

  describe "slug auto-derivation" do
    it "derives the slug from the title on create when slug is blank" do
      page = create(:page, title: "About Us", slug: "")
      expect(page.slug).to eq("about-us")
    end

    it "does not overwrite an explicit slug" do
      page = create(:page, title: "About Us", slug: "custom-slug")
      expect(page.slug).to eq("custom-slug")
    end

    it "does not re-derive the slug on update" do
      page = create(:page, title: "About Us", slug: "")
      page.update!(title: "New Title")
      expect(page.slug).to eq("about-us")
    end
  end

  describe "scopes" do
    let!(:draft)     { create(:page, published: false, show_in_nav: false, show_in_footer: false) }
    let!(:nav_page)  { create(:page, :in_nav) }
    let!(:foot_page) { create(:page, :in_footer) }
    let!(:both)      { create(:page, published: true, show_in_nav: true, show_in_footer: true) }

    describe ".published" do
      it "returns only published pages" do
        expect(Page.published).to include(nav_page, foot_page, both)
        expect(Page.published).not_to include(draft)
      end
    end

    describe ".in_nav" do
      it "returns published pages with show_in_nav true" do
        expect(Page.in_nav).to include(nav_page, both)
        expect(Page.in_nav).not_to include(draft, foot_page)
      end

      it "orders by position then id" do
        p1 = create(:page, :in_nav, position: 2)
        p2 = create(:page, :in_nav, position: 1)
        expect(Page.in_nav.to_a.index(p2)).to be < Page.in_nav.to_a.index(p1)
      end
    end

    describe ".in_footer" do
      it "returns published pages with show_in_footer true" do
        expect(Page.in_footer).to include(foot_page, both)
        expect(Page.in_footer).not_to include(draft, nav_page)
      end
    end
  end
end
