module WorkOrders
  class GenerateMilestoneInvoiceService
    Result = Data.define(:invoice, :error) do
      def success? = error.nil?
    end

    def self.call(milestone:)
      return Result.new(invoice: nil, error: "Invoice already generated") if milestone.invoice_generated?

      invoice = nil

      ActiveRecord::Base.transaction do
        work_order = milestone.work_order

        invoice = Invoice.create!(
          user:                 work_order.user,
          work_order_milestone: milestone,
          total_cents:          milestone.amount_cents
        )
        invoice.invoice_items.create!(
          name:         milestone.name,
          amount_cents: milestone.amount_cents
        )
        milestone.update_columns(invoice_generated: true)
      end

      WorkOrderMailer.milestone_invoice(invoice).deliver_later

      Result.new(invoice:, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(invoice: nil, error: e.message)
    end
  end
end
