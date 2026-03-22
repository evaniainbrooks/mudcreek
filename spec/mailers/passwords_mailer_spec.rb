require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:user) { create(:user) }

  describe "#reset" do
    subject(:mail) { PasswordsMailer.reset(user) }

    it "sends to the user" do
      expect(mail.to).to eq([user.email_address])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Reset your password")
    end

    it "includes a password reset link in the HTML body" do
      expect(mail.html_part.body.to_s).to include("/passwords/")
      expect(mail.html_part.body.to_s).to include("/edit")
    end

    it "mentions the expiry in the HTML body" do
      expect(mail.html_part.body.to_s).to include("15 minutes")
    end

    it "includes a password reset link in the text body" do
      expect(mail.text_part.body.to_s).to include("/passwords/")
      expect(mail.text_part.body.to_s).to include("/edit")
    end

    it "mentions the expiry in the text body" do
      expect(mail.text_part.body.to_s).to include("15 minutes")
    end
  end
end
