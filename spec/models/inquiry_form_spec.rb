require "rails_helper"

RSpec.describe InquiryForm, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:recipient) { create(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "requires a notification recipient" do
      form = InquiryForm.new(name: "Contact", slug: "contact", notification_recipient: nil)
      expect(form).not_to be_valid
      expect(form.errors[:notification_recipient]).to be_present
    end

    it "requires a valid slug format" do
      form = build(:inquiry_form, slug: "Has Spaces!")
      expect(form).not_to be_valid
      expect(form.errors[:slug]).to be_present
    end

    it "accepts a valid slug" do
      expect(build(:inquiry_form, slug: "contact-us-123")).to be_valid
    end

    it "enforces slug uniqueness within the tenant" do
      create(:inquiry_form, slug: "contact")
      expect(build(:inquiry_form, slug: "contact")).not_to be_valid
    end
  end

  describe "slug auto-derivation" do
    it "derives slug from name on create when blank" do
      form = create(:inquiry_form, name: "Get In Touch", slug: "")
      expect(form.slug).to eq("get-in-touch")
    end

    it "does not overwrite an explicit slug" do
      form = create(:inquiry_form, name: "Contact Us", slug: "my-custom-slug")
      expect(form.slug).to eq("my-custom-slug")
    end
  end

  describe ".published" do
    it "returns only published forms" do
      published   = create(:inquiry_form, :published)
      unpublished = create(:inquiry_form, :unpublished)
      expect(InquiryForm.published).to include(published)
      expect(InquiryForm.published).not_to include(unpublished)
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      form = build(:inquiry_form, slug: "contact-us")
      expect(form.to_param).to eq("contact-us")
    end
  end
end
