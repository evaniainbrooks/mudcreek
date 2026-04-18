require "rails_helper"

RSpec.describe Page, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it "belongs to a tenant" do
      page = create(:page, title: "About", slug: "about")
      expect(page.tenant).to eq(Current.tenant)
    end
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
      create(:page, title: "Terms", slug: "terms")
      duplicate = build(:page, title: "Terms Again", slug: "terms")
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
    describe ".published" do
      it "returns published pages and excludes drafts" do
        pub  = create(:page, title: "Published", slug: "published", published: true)
        draft = create(:page, title: "Draft", slug: "draft", published: false)

        expect(Page.published).to include(pub)
        expect(Page.published).not_to include(draft)
      end
    end

    describe ".in_nav" do
      it "returns published pages with show_in_nav true" do
        shown  = create(:page, title: "Nav Shown", slug: "nav-shown",   published: true,  show_in_nav: true)
        hidden = create(:page, title: "Nav Hidden", slug: "nav-hidden", published: false, show_in_nav: true)
        no_nav = create(:page, title: "No Nav",     slug: "no-nav",     published: true,  show_in_nav: false)

        result = Page.in_nav
        expect(result).to include(shown)
        expect(result).not_to include(hidden, no_nav)
      end

      it "orders by position then id" do
        p1 = create(:page, title: "First",  slug: "first",  published: true, show_in_nav: true, position: 2)
        p2 = create(:page, title: "Second", slug: "second", published: true, show_in_nav: true, position: 1)

        expect(Page.in_nav.to_a).to eq([p2, p1])
      end
    end
  end
end
