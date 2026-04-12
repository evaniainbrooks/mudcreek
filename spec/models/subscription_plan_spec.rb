require "rails_helper"

RSpec.describe SubscriptionPlan, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it "requires a name" do
      plan = SubscriptionPlan.new(amount_cents: 1000, kind: :month_to_month)
      expect(plan).not_to be_valid
      expect(plan.errors[:name]).to be_present
    end

    it "enforces name uniqueness within a tenant" do
      create(:subscription_plan, name: "Basic")
      plan = SubscriptionPlan.new(name: "Basic", amount_cents: 1000, kind: :month_to_month)
      expect(plan).not_to be_valid
      expect(plan.errors[:name]).to be_present
    end

    it "requires amount_cents greater than zero" do
      plan = SubscriptionPlan.new(name: "Bad", amount_cents: 0, kind: :month_to_month)
      expect(plan).not_to be_valid
      expect(plan.errors[:amount_cents]).to be_present
    end
  end

  describe "associations" do
    it "restricts deletion when subscriptions exist" do
      plan = create(:subscription_plan)
      create(:subscription, subscription_plan: plan)
      expect { plan.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
    end
  end
end
