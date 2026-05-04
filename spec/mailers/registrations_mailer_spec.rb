require "rails_helper"

RSpec.describe RegistrationsMailer, type: :mailer do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:user) { create(:user, :unactivated, first_name: "Bob", last_name: "Jones") }

  describe "#activate" do
    subject(:mail) { RegistrationsMailer.activate(user) }

    it "sends to the user" do
      expect(mail.to).to eq([user.email_address])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Activate your account")
    end

    it "addresses the user by first name in the HTML body" do
      expect(mail.html_part.body.to_s).to include("Bob")
    end

    it "includes an activation link in the HTML body" do
      expect(mail.html_part.body.to_s).to include("activation")
    end

    it "includes an activation URL in the HTML body" do
      expect(mail.html_part.body.to_s).to include("/activations")
    end

    it "addresses the user by first name in the text body" do
      expect(mail.text_part.body.to_s).to include("Bob")
    end

    it "includes an activation link in the text body" do
      expect(mail.text_part.body.to_s).to include("activation")
    end
  end

  describe "#user_registered" do
    subject(:mail) { RegistrationsMailer.user_registered(user) }

    it "sends to the tenant email address" do
      expect(mail.to).to eq([Current.tenant.email_address])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("New user registration: Bob Jones")
    end

    it "includes the user's name in the HTML body" do
      expect(mail.html_part.body.to_s).to include("Bob Jones")
    end

    it "includes the user's email address in the HTML body" do
      expect(mail.html_part.body.to_s).to include(user.email_address)
    end

    it "includes the user's name in the text body" do
      expect(mail.text_part.body.to_s).to include("Bob Jones")
    end

    it "includes the user's email address in the text body" do
      expect(mail.text_part.body.to_s).to include(user.email_address)
    end
  end
end
