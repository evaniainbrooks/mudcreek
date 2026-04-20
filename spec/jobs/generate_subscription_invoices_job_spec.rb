require "rails_helper"

RSpec.describe GenerateSubscriptionInvoicesJob, type: :job do
  let!(:tenant) { Current.tenant = create(:tenant) }
  let(:plan)    { create(:subscription_plan, amount_cents: 4_900) }
  let(:user)    { create(:user) }

  after { Current.tenant = nil }

  def create_due_subscription(**attrs)
    create(:subscription, user: user, subscription_plan: plan, renews_at: Date.yesterday, **attrs)
  end

  context "with a due active subscription and no card on file" do
    let!(:subscription) { create_due_subscription }

    it "creates an invoice" do
      expect { described_class.perform_now }.to change(Invoice, :count).by(1)
    end

    it "creates an invoice item named after the plan" do
      described_class.perform_now
      expect(Invoice.last.invoice_items.first.name).to eq(plan.name)
    end

    it "sets invoice total from the subscription amount" do
      described_class.perform_now
      expect(Invoice.last.total_cents).to eq(subscription.amount_cents)
    end

    it "links the invoice to the subscription" do
      described_class.perform_now
      expect(Invoice.last.subscription).to eq(subscription)
    end

    it "sends a subscription mailer" do
      mail = double("mail", deliver_later: true)
      allow(SubscriptionMailer).to receive(:invoice_generated).and_return(mail)
      expect(mail).to receive(:deliver_later)
      described_class.perform_now
    end
  end

  context "with a due active subscription and a card on file" do
    before { user.update_columns(default_square_card_id: "card_abc") }
    let!(:subscription) { create_due_subscription }

    it "enqueues ChargeInvoiceJob" do
      expect { described_class.perform_now }.to have_enqueued_job(ChargeInvoiceJob)
    end
  end

  context "when an unpaid invoice already exists for the subscription" do
    let!(:subscription) { create_due_subscription }

    before do
      described_class.perform_now  # first run creates the invoice
    end

    it "does not create a duplicate invoice" do
      expect { described_class.perform_now }.not_to change(Invoice, :count)
    end
  end

  context "with a lapsed subscription" do
    let!(:subscription) { create_due_subscription(status: :lapsed) }

    it "does not create an invoice" do
      expect { described_class.perform_now }.not_to change(Invoice, :count)
    end
  end

  context "with a cancelled subscription" do
    let!(:subscription) { create_due_subscription(status: :cancelled) }

    it "does not create an invoice" do
      expect { described_class.perform_now }.not_to change(Invoice, :count)
    end
  end

  context "with a subscription not yet due" do
    let!(:subscription) { create(:subscription, user: user, subscription_plan: plan, renews_at: Date.tomorrow) }

    it "does not create an invoice" do
      expect { described_class.perform_now }.not_to change(Invoice, :count)
    end
  end

  context "with a due monthly subscription" do
    let(:monthly_plan) { create(:subscription_plan, subscription_type: :monthly, amount_cents: 4_900) }
    let!(:subscription) { create(:subscription, user: user, subscription_plan: monthly_plan, renews_at: Date.yesterday) }

    it "advances renews_at when the invoice is generated" do
      expect { described_class.perform_now }
        .to change { subscription.reload.renews_at }.from(Date.yesterday).to(Date.yesterday + 1.month)
    end

    it "still creates the invoice" do
      expect { described_class.perform_now }.to change(Invoice, :count).by(1)
    end

    it "renews_at is already at the next period so a second invoice can be generated after paying the first" do
      described_class.perform_now
      Invoice.last.update!(status: :paid)
      travel_to(Date.yesterday + 1.month) { described_class.perform_now }
      expect(Invoice.count).to eq(2)
    end
  end

  context "with a due month_to_month subscription" do
    let!(:subscription) { create_due_subscription }

    it "does not advance renews_at when the invoice is generated" do
      expect { described_class.perform_now }
        .not_to change { subscription.reload.renews_at }
    end
  end
end
