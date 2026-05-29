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
        location   = work_order.location
        ratio      = milestone.percentage / 100.0

        prorated_items = work_order.work_order_items.map do |item|
          TaxCalculator::LineItem.new(
            amount_cents: (item.line_total_cents * ratio).round,
            tax_exempt:   item.tax_exempt
          )
        end

        tax_cents = TaxCalculator.new(prorated_items, location.tax_rate).tax_cents

        invoice = Invoice.create!(
          user:                 work_order.user,
          work_order_milestone: milestone,
          total_cents:          milestone.amount_cents + tax_cents
        )

        prorated_items.zip(work_order.work_order_items) do |prorated, item|
          invoice.invoice_items.create!(name: item.name, amount_cents: prorated.amount_cents)
        end

        if tax_cents > 0
          invoice.invoice_items.create!(
            name:         "Tax (#{location.tax_rate_percent}%)",
            amount_cents: tax_cents
          )
        end

        milestone.update_columns(invoice_generated: true)
      end

      WorkOrderMailer.milestone_invoice(invoice).deliver_later

      Result.new(invoice:, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(invoice: nil, error: e.message)
    end
  end
end
