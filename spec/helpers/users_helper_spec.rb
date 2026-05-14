require "rails_helper"

RSpec.describe UsersHelper, type: :helper do
  let(:tenant) { create(:tenant) }

  before { Current.tenant = tenant }
  after  { Current.tenant = nil }

  describe "#render_birthdays_table" do
    let(:user) { create(:user, birthdate: 30.years.ago.to_date) }
    let(:kid)  { create(:kid, user: user, birthdate: 8.years.ago.to_date) }

    let(:user_entry) do
      {
        type:          :user,
        record:        user,
        next_birthday: Date.current
      }
    end

    let(:kid_entry) do
      {
        type:          :kid,
        record:        kid,
        next_birthday: Date.current + 30
      }
    end

    subject(:html) { Capybara.string(helper.render_birthdays_table(entries: [user_entry, kid_entry]).to_s) }

    it "renders a table" do
      expect(html).to have_css("table")
    end

    it "renders column headers" do
      %w[Type Name Parent Birthdate Turns].each do |header|
        expect(html).to have_css("th", text: header)
      end
    end

    it "renders a User badge for user entries" do
      expect(html).to have_css(".badge", text: "User")
    end

    it "renders a Kid badge for kid entries" do
      expect(html).to have_css(".badge", text: "Kid")
    end

    it "renders a Today! badge when the birthday is today" do
      expect(html).to have_css(".badge", text: "Today!")
    end

    it "renders the days until birthday for future birthdays" do
      expect(html).to have_text("30 days")
    end
  end

  describe "#render_users_table" do
    let(:role)         { Role.create!(name: "member", description: "Member") }
    let(:active_user)  { create(:user, role: role) }
    let(:q)            { User.ransack(nil) }

    before do
      controller.request.path_parameters[:controller] = "admin/users"
      controller.request.path_parameters[:action] = "index"
    end

    subject(:html) { Capybara.string(helper.render_users_table(users: [active_user], q: q).to_s) }

    it "renders a table" do
      expect(html).to have_css("table")
    end

    it "renders column headers" do
      %w[Name Email Role].each do |header|
        expect(html).to have_css("th", text: header)
      end
    end

    it "links the user name to the admin user path" do
      expect(html).to have_link(active_user.name, href: admin_user_path(active_user))
    end

    it "renders the user's email as a mailto link" do
      expect(html).to have_css("a[href='mailto:#{active_user.email_address}']")
    end

    it "renders a Disable button for an active user" do
      expect(html).to have_button("Disable")
    end

    context "with a disabled user" do
      let(:disabled_user) do
        create(:user).tap { |u| u.update!(disabled_at: Time.current, disabled_email_address: u.email_address) }
      end

      subject(:html) { Capybara.string(helper.render_users_table(users: [disabled_user], q: q).to_s) }

      it "renders an Enable button" do
        expect(html).to have_button("Enable")
      end
    end
  end
end
